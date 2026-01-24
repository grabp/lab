resource "proxmox_virtual_environment_container" "lxc" {
  node_name   = var.node_name
  vm_id       = var.vm_id
  description = var.description
  tags        = concat(["nixos", "linux", "lxc"], var.tags)

  # CPU configuration
  cpu {
    cores = var.cores
  }

  # Memory configuration
  memory {
    dedicated = var.memory
    swap      = var.memory_swap
  }

  # Disk configuration
  disk {
    datastore_id = var.storage
    file_id      = var.image_file_id
    size         = var.disk_size
  }

  # Network configuration
  network_interface {
    name    = "eth0"
    bridge  = var.bridge
    enabled = true
    
    # Static IP configuration if provided
    ip_addresses = var.ip_address != null ? [
      "${var.ip_address}/${var.prefix_length}"
    ] : []
    
    dynamic "ipv4" {
      for_each = var.gateway != null ? [1] : []
      content {
        gateway = var.gateway
      }
    }
  }

  # Operating system
  operating_system {
    template_file_id = var.image_file_id
    type             = "unmanaged"
  }

  # Container features
  features {
    nesting = var.features.nesting
    keyctl  = var.features.keyctl
  }

  # Unprivileged container
  unprivileged = var.unprivileged

  # Start container after creation
  started = var.start_on_create

  # Lifecycle: prevent destruction of running containers
  lifecycle {
    prevent_destroy = var.prevent_destroy
  }
}

