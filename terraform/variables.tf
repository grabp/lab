variable "proxmox_host" {
  description = "Proxmox host IP or hostname"
  type        = string
  default     = "10.0.0.50"
}

variable "proxmox_user" {
  description = "Proxmox API user"
  type        = string
  default     = "root@pam"
}

# proxmox_password is read from SOPS secrets file via data source
# No variable needed - see provider.tf

variable "proxmox_insecure" {
  description = "Skip TLS verification (for self-signed certs)"
  type        = bool
  default     = true
}

variable "ssh_user" {
  description = "SSH user for image uploads"
  type        = string
  default     = "root"
}

variable "ssh_private_key" {
  description = "SSH private key path for image uploads"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "default_storage" {
  description = "Default storage pool"
  type        = string
  default     = "local-lvm"
}

variable "default_bridge" {
  description = "Default network bridge"
  type        = string
  default     = "vmbr0"
}

