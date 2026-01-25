variable "node_name" {
  description = "Proxmox node name"
  type        = string
}

variable "local_image_path" {
  description = "Local path to image file. If null, will auto-detect from instance_name"
  type        = string
  default     = null
}

variable "instance_name" {
  description = "Instance name for auto-detecting image path. Used when local_image_path is null. Auto-detects from results/<instance_name>/result/"
  type        = string
  default     = null
}

variable "workspace_root" {
  description = "Path to workspace root (for relative path resolution). Defaults to parent of terraform/ directory"
  type        = string
  default     = ".."
}

variable "image_type" {
  description = "Image type: 'vm' or 'lxc'"
  type        = string
  validation {
    condition     = contains(["vm", "lxc"], var.image_type)
    error_message = "Image type must be 'vm' or 'lxc'."
  }
}

variable "storage" {
  description = "Storage pool/datastore ID for file upload"
  type        = string
  default     = "local"
}

