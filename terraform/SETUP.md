# Terraform Setup Guide

Quick setup guide for Terraform Proxmox integration.

## Prerequisites

1. **Proxmox API Access**
   - Ensure you have Proxmox root password or API token
   - SSH access to Proxmox host

2. **Add Proxmox Credentials to SOPS**

   Edit `secrets/terraform.yaml` (separate from common.yaml for security):
   ```bash
   sops secrets/terraform.yaml
   ```

   Update the `proxmox_password` value:
   ```yaml
   proxmox_password: "your-proxmox-password-or-api-token"
   ```

   **Note:** This file is separate from `secrets/common.yaml` to avoid exposing Proxmox credentials to VMs/containers.

   **For API Token (recommended):**
   - Create API token in Proxmox UI: Datacenter → Permissions → API Tokens
   - Format: `username@realm!token-name:token-value`
   - Example: `terraform@pam!terraform-token:abc123...`

3. **SSH Key Setup**
   - Ensure SSH key is available: `~/.ssh/id_rsa`
   - Or configure path in `terraform/variables.tf`
   - SSH agent should be running

## Initial Setup

```bash
# 1. Initialize Terraform
cd terraform
terraform init

# 2. Verify configuration
terraform validate

# 3. Test connection (optional)
terraform plan
```

## Creating Your First Resource

### Example: Caddy Container

1. **Create NixOS config:**
   ```bash
   just new-container caddy-1
   ```

2. **Edit configuration:**
   - `containers/caddy-1/configuration.nix` - Service config
   - `containers/caddy-1/proxmox.nix` - Resource limits

3. **Build image:**
   ```bash
   nix build .#caddy-1
   ```

4. **Create Terraform resource:**

   Create `terraform/instances/caddy-1.tf`:
   ```hcl
   module "caddy_image" {
     source = "../modules/image-upload"
     
     node_name        = "10.0.0.50"
     local_image_path = "../result/tarball/caddy-1.tar.xz"
     image_type       = "lxc"
   }
   
   module "caddy_instance" {
     source = "../modules/proxmox-lxc"
     
     name         = "caddy-1"
     node_name    = "10.0.0.50"
     description  = "Caddy reverse proxy"
     cores        = 1
     memory       = 512
     disk_size    = "4G"
     storage      = "local-lvm"
     bridge       = "vmbr0"
     image_file_id = module.caddy_image.file_id
     
     ip_address    = "10.0.0.10"
     prefix_length = 24
     gateway       = "10.0.0.1"
     
     unprivileged = true
     start_on_create = true
   }
   ```

5. **Apply Terraform:**
   ```bash
   just tf-plan    # Preview changes
   just tf-apply   # Create resource
   ```

6. **Bootstrap secrets:**
   ```bash
   just bootstrap-container caddy-1 10.0.0.10
   ```

7. **Deploy NixOS config:**
   ```bash
   just deploy-container caddy-1
   ```

## Troubleshooting

### Provider Authentication Fails

**Error:** `authentication failed`

**Solutions:**
1. Verify password in SOPS: `sops secrets/terraform.yaml`
2. Check Proxmox API token format
3. Try `insecure = true` in `provider.tf` for self-signed certs

### Image Upload Fails

**Error:** `failed to upload file`

**Solutions:**
1. Check SSH access: `ssh root@10.0.0.50`
2. Verify image path exists: `ls -la result/tarball/`
3. Check Proxmox storage space
4. Verify SSH key permissions: `chmod 600 ~/.ssh/id_rsa`

### State Lock Issues

**Error:** `Error acquiring the state lock`

**Solution:**
```bash
terraform force-unlock <LOCK_ID>
```

### Module Not Found

**Error:** `Module not found`

**Solution:**
```bash
terraform init -upgrade
```

## Next Steps

- See [terraform/README.md](./README.md) for detailed documentation
- See [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md) for architecture overview
- Check example files: `terraform/instances/example-*.tf`

