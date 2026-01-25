# Provider configuration for Proxmox Virtual Environment
#
# This file configures the Proxmox provider and handles authentication.
# Secrets are managed via SOPS to keep Proxmox credentials separate from VM/container secrets.
#
# Authentication Priority:
#   1. Terraform variable: proxmox_api_token (set via TF_VAR_proxmox_api_token)
#   2. SOPS secret: proxmox_api_token from secrets/terraform.yaml
#   3. Environment variable: PROXMOX_VE_API_TOKEN
#   4. Fallback: Username/password from SOPS secrets (proxmox_password)
#
# Security Note:
#   Using separate terraform.yaml secrets file prevents exposing Proxmox credentials
#   to VMs/containers that may read common.yaml secrets.

# SOPS data source for reading encrypted secrets
data "sops_file" "terraform_secrets" {
  source_file = "../secrets/terraform.yaml"
}

provider "proxmox" {
  endpoint = "https://${var.proxmox_host}:8006"
  insecure = var.proxmox_insecure

  # Authentication: Use API token if available, otherwise fall back to username/password
  api_token = local.proxmox_api_token != null ? local.proxmox_api_token : null
  username  = local.proxmox_api_token == null ? var.proxmox_user : null
  password  = local.proxmox_api_token == null ? data.sops_file.terraform_secrets.data["proxmox_password"] : null

  # SSH configuration for file uploads and snippets
  # Required when uploading VM images or LXC templates
  ssh {
    agent    = true
    username = var.ssh_user
  }
}