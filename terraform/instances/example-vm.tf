# Example VM configuration
# Copy this file and modify for your VM

# Step 1: Build NixOS image first
#   nix build .#web-1
#   This creates: result/*.vma.zst

# Step 2: Upload image and create VM
# module "example_vm" {
#   source = "../modules/image-upload"
#   
#   node_name        = "10.0.0.50"
#   local_image_path = "../result/web-1.vma.zst"
#   image_type       = "vm"
# }
# 
# module "example_vm_instance" {
#   source = "../modules/proxmox-vm"
#   
#   name         = "web-1"
#   node_name    = "10.0.0.50"
#   description  = "Example web server"
#   cores        = 2
#   memory       = 2048
#   disk_size    = "32G"
#   storage      = "local-lvm"
#   bridge       = "vmbr0"
#   image_file_id = module.example_vm.file_id
#   
#   start_on_create = true
# }

