variable "name" {
  description = "VM name"
  type        = string
}

variable "node_name" {
  description = "Proxmox node name"
  type        = string
}

variable "description" {
  description = "VM description"
  type        = string
  default     = ""
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "sockets" {
  description = "Number of CPU sockets"
  type        = number
  default     = 1
}

variable "cpu_type" {
  description = "CPU type"
  type        = string
  default     = "host"
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 2048
}

variable "disk_size" {
  description = "Disk size (e.g., '32G')"
  type        = string
  default     = "32G"
}

variable "storage" {
  description = "Storage pool"
  type        = string
  default     = "local-lvm"
}

variable "image_file_id" {
  description = "Image file ID (from proxmox_virtual_environment_file_upload)"
  type        = string
}

variable "bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "bios" {
  description = "BIOS type"
  type        = string
  default     = "seabios"
}

variable "start_on_create" {
  description = "Start VM immediately after creation"
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

