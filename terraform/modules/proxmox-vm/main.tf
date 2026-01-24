resource "proxmox_virtual_environment_vm" "vm" {
  name        = var.name
  node_name   = var.node_name
  description = var.description
  tags        = concat(["nixos", "linux"], var.tags)

  # CPU configuration
  cpu {
    cores  = var.cores
    sockets = var.sockets
    type   = var.cpu_type
  }

  # Memory configuration
  memory {
    dedicated = var.memory
  }

  # Disk configuration
  disk {
    datastore_id = var.storage
    file_id      = var.image_file_id
    interface    = "scsi0"
    size         = var.disk_size
    file_format  = "raw"
  }

  # Network configuration
  network_device {
    bridge = var.bridge
  }

  # Operating system
  operating_system {
    type = "l26" # Linux 2.6+
  }

  # BIOS settings
  bios = var.bios

  # Start VM after creation
  started = var.start_on_create

  # Lifecycle: prevent destruction of running VMs
  lifecycle {
    prevent_destroy = var.prevent_destroy
  }
}

