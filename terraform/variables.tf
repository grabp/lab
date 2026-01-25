# Variable definitions for Terraform configuration
#
# Variables are organized by logical groups:
# 1. Provider/Authentication variables
# 2. Network configuration variables
# 3. Storage and SSH configuration variables

# ============================================================================
# Provider and Authentication Variables
# ============================================================================

variable "proxmox_host" {
  description = "Proxmox host IP address or hostname (e.g., '10.0.0.50' or 'pve.example.com')"
  type        = string
  default     = "10.0.0.50"

  validation {
    condition     = var.proxmox_host != null && var.proxmox_host != ""
    error_message = "Proxmox host cannot be null or empty."
  }
}

variable "proxmox_api_token" {
  description = <<-EOT
    Proxmox API token for authentication (format: 'user@realm!token-id=secret').
    
    Authentication priority:
    1. This variable (via TF_VAR_proxmox_api_token environment variable)
    2. SOPS secret: proxmox_api_token from secrets/terraform.yaml
    3. Environment variable: PROXMOX_VE_API_TOKEN
    4. Fallback: Username/password from SOPS secrets
    
    If null, the provider will fall back to username/password authentication.
    EOT
  type        = string
  default     = null
  sensitive   = true
}

variable "proxmox_user" {
  description = "Proxmox API username (used when api_token is not provided). Format: 'user@realm' (e.g., 'root@pam')"
  type        = string
  default     = "root@pam"
}

# Note: proxmox_password is read from SOPS secrets file via data source
# No variable needed - see provider.tf

variable "proxmox_insecure" {
  description = "Skip TLS certificate verification for Proxmox API (useful for self-signed certificates in homelab environments)"
  type        = bool
  default     = true
}

variable "proxmox_node_name" {
  description = <<-EOT
    Proxmox node name (if different from proxmox_host).
    
    If null or empty, the configuration will use proxmox_host value.
    This is useful when the hostname/IP differs from the actual node name in Proxmox cluster.
    EOT
  type        = string
  default     = "pve"

  validation {
    condition     = var.proxmox_node_name == null || (var.proxmox_node_name != null && var.proxmox_node_name != "")
    error_message = "Proxmox node name cannot be an empty string. Use null to auto-detect from proxmox_host."
  }
}

# ============================================================================
# Network Configuration Variables
# ============================================================================

variable "network_gateway" {
  description = "Default network gateway IP address for VMs and containers"
  type        = string
  default     = "10.0.0.1"

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", var.network_gateway))
    error_message = "Network gateway must be a valid IPv4 address."
  }
}

variable "network_prefix_length" {
  description = "Network prefix length in CIDR notation (e.g., 24 for /24 subnet)"
  type        = number
  default     = 24

  validation {
    condition     = var.network_prefix_length >= 8 && var.network_prefix_length <= 30
    error_message = "Network prefix length must be between 8 and 30 (inclusive)."
  }
}

variable "network_dns_server" {
  description = "Primary DNS server IP address for VMs and containers"
  type        = string
  default     = "10.0.0.53" # PiHole

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", var.network_dns_server))
    error_message = "DNS server must be a valid IPv4 address."
  }
}

variable "default_bridge" {
  description = "Default network bridge interface name for VMs and containers (e.g., 'vmbr0', 'vmbr1')"
  type        = string
  default     = "vmbr0"

  validation {
    condition     = can(regex("^vmbr[0-9]+$", var.default_bridge))
    error_message = "Bridge name must follow the format 'vmbr<number>' (e.g., 'vmbr0')."
  }
}

# ============================================================================
# Storage and SSH Configuration Variables
# ============================================================================

variable "default_storage" {
  description = "Default Proxmox storage pool/datastore name for VM and container disks (e.g., 'local-lvm', 'local', 'ceph-pool')"
  type        = string
  default     = "local-lvm"

  validation {
    condition     = var.default_storage != null && var.default_storage != ""
    error_message = "Default storage cannot be null or empty."
  }
}

variable "ssh_user" {
  description = "SSH username for image uploads and file operations on Proxmox host"
  type        = string
  default     = "root"
}

variable "ssh_private_key" {
  description = <<-EOT
    Path to SSH private key file for image uploads.
    
    This is used as a fallback when SSH agent is not available.
    Default assumes standard SSH key location. Can be absolute or relative path.
    EOT
  type        = string
  default     = "~/.ssh/id_rsa"
}