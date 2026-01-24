terraform {
  required_version = ">= 1.5"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.93"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 1.0"
    }
  }

  # Store state locally (for homelab, Git is fine)
  # For production, consider remote state (S3, etc.)
  backend "local" {
    path = "terraform.tfstate"
  }
}

