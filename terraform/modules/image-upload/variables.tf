variable "node_name" {
  description = "Proxmox node name"
  type        = string
}

variable "local_image_path" {
  description = "Local path to image file"
  type        = string
}

variable "image_type" {
  description = "Image type: 'vm' or 'lxc'"
  type        = string
  validation {
    condition     = contains(["vm", "lxc"], var.image_type)
    error_message = "Image type must be 'vm' or 'lxc'."
  }
}

