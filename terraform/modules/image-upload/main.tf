# Upload VM image to Proxmox
resource "proxmox_virtual_environment_file" "vm_image" {
  count = var.image_type == "vm" ? 1 : 0

  node_name     = var.node_name
  datastore_id  = "local"
  content_type  = "vztmpl"
  source_file {
    path = var.local_image_path
  }
}

# Upload LXC template to Proxmox
resource "proxmox_virtual_environment_file" "lxc_template" {
  count = var.image_type == "lxc" ? 1 : 0

  node_name     = var.node_name
  datastore_id  = "local"
  content_type  = "vztmpl"
  source_file {
    path = var.local_image_path
  }
}

output "file_id" {
  description = "Uploaded file ID"
  value = var.image_type == "vm" 
    ? proxmox_virtual_environment_file.vm_image[0].id
    : proxmox_virtual_environment_file.lxc_template[0].id
}

