# Secrets Management (sops-nix)

This repository uses **sops-nix + age** to manage secrets safely in a **public Git repository**.

Secrets are:
- encrypted locally
- committed encrypted
- decrypted only on the target VM at runtime
- never stored in the Nix store

---

## Overview

- Secrets live in `secrets/*.yaml`
- Encryption is done using **age**
- Private keys live **only on your machine and the VMs**
- VMs are updated via `nixos-rebuild --target-host`

---

## Directory Layout

```text
secrets/
├── common.yaml          # shared secrets
└── hosts/
    ├── web-1.yaml       # host-specific secrets
    └── db-1.yaml
```

Secret declarations live in Nix files:

```text
modules/
├── base/secrets.nix
hosts/*/secrets.nix
```

## Initial Setup (One-Time)

1. Install tools locally

```bash
nix-shell -p sops age
```

2. Generate an age key

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
```
Save the public key output — you’ll need it next.

3. Configure SOPS encryption rules

Add your public key to .sops.yaml in the repo root:

```bash
creation_rules:
  - path_regex: secrets/.*\.yaml
    age: age1YOUR_PUBLIC_KEY_HERE
```

## Creating/Editing Secrets

Create or edit secrets using:

```bash
sops secrets/common.yaml
sops secrets/hosts/web-1.yaml
```

Secrets are encrypted automatically on save.

## Declaring Secrets in NixOS

Example:

```nix
sops.secrets.db_password = {
  sopsFile = ../../secrets/hosts/web-1.yaml;
  owner = "postgres";
  mode = "0400";
};
```

Secrets are exposed at runtime under:
```text
/run/secrets/<name>
```

## Bootstrapping a VM (One-Time)

Each VM needs the age private key once.

From your local machine:
```bash
./bootstrap-age.sh user@vm
```
After this, the VM can decrypt secrets automatically.

## Security Notes
❌ Never commit private age keys
❌ Never read secrets into Nix evaluation
❌ Never store secrets in .nix files
✅ Secrets are files, not values

If a VM loses its age key, re-run the bootstrap step.

## Step-by-step: rotating keys safely

1. Generate a new age key (locally)

```bash
age-keygen -o ~/.config/sops/age/keys-new.txt
```

You now have:

old key: keys.txt

new key: keys-new.txt

2. Update .sops.yaml (add new public key)

Both keys are now valid

3. Re-encrypt all secrets
```bash
sops updatekeys secrets/common.yaml
sops updatekeys secrets/hosts/*.yaml
```

Commit the changes.

4. Deploy new key to VMs (one-by-one)
```bash
./bootstrap-age.sh user@vm
```

5. Update VMs normally

6. Remove old key (after all VMs updated)

- Remove old public key from .sops.yaml
- Run sops updatekeys again
- Commit
- Delete old private key from laptop
- Optionally delete backups

Rotation complete 🎉
