# SOPS provider for reading encrypted secrets
# Using separate terraform.yaml to avoid exposing Proxmox credentials to VMs/containers
data "sops_file" "terraform_secrets" {
  source_file = "../secrets/terraform.yaml"
}

provider "proxmox" {
  endpoint = "https://${var.proxmox_host}:8006"
  username = var.proxmox_user
  password = data.sops_file.terraform_secrets.data["proxmox_password"]
  insecure = var.proxmox_insecure

  ssh {
    agent    = true
    username = var.ssh_user
  }
}

