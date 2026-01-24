# Secrets Management

I use **sops-nix + age** to manage secrets in this repo. The cool thing is that secrets are encrypted, so you can commit them to Git without worrying. They only get decrypted on the actual VMs when needed.

## How It Works

Basically:
- You encrypt secrets locally with age
- Commit the encrypted files to Git
- VMs decrypt them at runtime using their own age key
- Secrets never end up in the Nix store

## Setup

### First Time Setup

1. Install sops and age:
```bash
nix-shell -p sops age
```

2. Generate an age key:
```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
```

Copy the public key that gets printed - you'll need it.

3. Add your public key to `.sops.yaml`:
```yaml
creation_rules:
  - path_regex: secrets/.*\.yaml
    age: age1YOUR_PUBLIC_KEY_HERE
```

That's it! Now you can encrypt secrets.

## Using Secrets

### Creating and Editing Secrets

When you create a new VM with `just new web-1`, it automatically opens the secret file for you. Otherwise, just use `sops` to edit them:
```bash
sops secrets/common.yaml
sops secrets/vms/web-1.yaml
sops secrets/terraform.yaml  # Terraform infrastructure secrets (separate for security)
```

**Secret File Organization:**
- `secrets/common.yaml` - Shared secrets for VMs/containers
- `secrets/vms/*.yaml` - Per-VM/container secrets
- `secrets/terraform.yaml` - **Terraform-only secrets** (Proxmox credentials, not deployed to VMs)

Note: Both VMs and containers use the `secrets/vms/` directory for their secrets. Terraform secrets are kept separate to avoid exposing infrastructure credentials to VMs/containers.

It opens in your editor, and when you save, it encrypts automatically.

### Declaring Secrets in Nix

In your VM's `secrets.nix` file:

```nix
{ ... }:

{
  sops.secrets.db_password = {
    sopsFile = ../../secrets/vms/web-1.yaml;
    owner = "postgres";
    mode = "0400";
  };
}
```

Then on the VM, the secret is available at `/run/secrets/db_password`.

### Bootstrapping VMs and Containers

Each VM or container needs the age key to decrypt secrets. Do this once per system:

**For VMs:**
```bash
just bootstrap web-1 10.0.0.69
```

**For Containers:**
```bash
just bootstrap-container app-1 10.0.0.100
```

The Justfile uses `SSH_USER` (defaults to `ops`) and connects via IP. This copies your age key to the system so it can decrypt secrets.

## Key Rotation

If you need to rotate keys (maybe someone left, or you just want to):

1. Generate a new key:
```bash
age-keygen -o ~/.config/sops/age/keys-new.txt
```

2. Add the new public key to `.sops.yaml` (keep the old one too for now)

3. Re-encrypt everything:
```bash
sops updatekeys secrets/common.yaml
sops updatekeys secrets/vms/*.yaml
```

4. Deploy the new key to all VMs/containers using the rotate-secrets command:
```bash
just rotate-secrets web-1 10.0.0.69
just rotate-secrets-container app-1 10.0.0.100
```

Or use the regular bootstrap command:
```bash
just bootstrap web-1 10.0.0.69
just bootstrap-container app-1 10.0.0.100
```

5. Once all VMs are updated, remove the old key from `.sops.yaml`, run `sops updatekeys` again, and delete the old private key.

### Quick Re-bootstrap

If you just need to re-deploy the same key (e.g., after VM recreation), use:
```bash
just rotate-secrets web-1 10.0.0.69
just rotate-secrets-container app-1 10.0.0.100
```

This is equivalent to `bootstrap` but makes it clear you're rotating/re-deploying keys.

## Common Issues

**VM/Container can't decrypt secrets?**
- Check if the key exists: `just ssh <name>` then `sudo ls /var/lib/sops-nix/key.txt`
- Or check connectivity first: `just health <name>`
- Re-bootstrap if it's missing: `just bootstrap <name> <ip>`
- Or use rotate-secrets: `just rotate-secrets <name> <ip>`

**Can't edit secrets?**
- Make sure your age key exists: `ls ~/.config/sops/age/keys.txt`
- Check your public key is in `.sops.yaml`

**Secret not found?**
- Make sure the key name in the YAML matches what you're referencing in Nix
- Check the `sopsFile` path is correct

## Important Notes

- ✅ Secrets are encrypted files, not values - don't try to read them in Nix evaluation
- ✅ Never commit your private age key
- ✅ Keep private keys only on your machine and the VMs
- ❌ Don't store secrets in `.nix` files directly

That's about it! If you need more details, check out the [sops-nix](https://github.com/Mic92/sops-nix) and [age](https://github.com/FiloSottile/age) docs.
