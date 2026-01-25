variable "name" {
  description = "Container name (used as hostname)"
  type        = string
}

variable "node_name" {
  description = "Proxmox node name"
  type        = string
}

variable "vm_id" {
  description = "Container ID (use null for auto-assign)"
  type        = number
  default     = null
}

variable "description" {
  description = "Container description"
  type        = string
  default     = ""
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 1
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 512
}

variable "memory_swap" {
  description = "Swap memory in MB"
  type        = number
  default     = 512
}

variable "disk_size" {
  description = "Disk size (e.g., '8G')"
  type        = string
  default     = "8G"
}

variable "storage" {
  description = "Storage pool"
  type        = string
  default     = "local-lvm"
}

variable "image_file_id" {
  description = "Image file ID (template cache)"
  type        = string
}

variable "bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "ip_address" {
  description = "Static IP address (CIDR format)"
  type        = string
  default     = null
}

variable "prefix_length" {
  description = "Network prefix length"
  type        = number
  default     = 24
}

variable "gateway" {
  description = "Gateway IP address (required if ip_address is set)"
  type        = string
  default     = null

  validation {
    condition     = var.gateway != null || var.ip_address == null
    error_message = "Gateway is required when ip_address is set."
  }
}

variable "unprivileged" {
  description = "Create unprivileged container"
  type        = bool
  default     = true
}

variable "features" {
  description = "Container features"
  type = object({
    nesting = bool
    keyctl  = bool
  })
  default = {
    nesting = true
    keyctl  = true
  }
}

variable "start_on_create" {
  description = "Start container immediately after creation"
  type        = bool
  default     = true
}

variable "prevent_destroy" {
  description = "Prevent accidental destruction"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags"
  type        = list(string)
  default     = []
}

variable "pool_id" {
  description = "Resource pool ID to assign container to (optional)"
  type        = string
  default     = null
}

