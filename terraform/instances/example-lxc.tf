# Example LXC container configuration
# Copy this file and modify for your container

# Step 1: Build NixOS container image first
#   nix build .#pihole-1
#   This creates: result/tarball/*.tar.xz

# Step 2: Upload template and create container
# module "example_lxc_image" {
#   source = "../modules/image-upload"
#   
#   node_name        = "10.0.0.50"
#   local_image_path = "../result/tarball/pihole-1.tar.xz"
#   image_type       = "lxc"
# }
# 
# module "example_lxc_instance" {
#   source = "../modules/proxmox-lxc"
#   
#   name         = "pihole-1"
#   node_name    = "10.0.0.50"
#   description  = "PiHole DNS server"
#   cores        = 1
#   memory       = 512
#   disk_size    = "4G"
#   storage      = "local-lvm"
#   bridge       = "vmbr0"
#   image_file_id = module.example_lxc_image.file_id
#   
#   # Static IP configuration
#   ip_address    = "10.0.0.53"
#   prefix_length = 24
#   gateway       = "10.0.0.1"
#   
#   unprivileged = true
#   features = {
#     nesting = true
#     keyctl  = true
#   }
#   
#   start_on_create = true
# }

