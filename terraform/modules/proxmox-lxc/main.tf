resource "proxmox_virtual_environment_container" "lxc" {
  node_name   = var.node_name
  vm_id       = var.vm_id
  description = var.description
  tags        = concat(["nixos", "linux", "lxc"], var.tags)
  pool_id     = var.pool_id

  # CPU configuration
  cpu {
    cores = var.cores
  }

  # Memory configuration
  memory {
    dedicated = var.memory
    swap      = var.memory_swap
  }

  # Disk configuration (root filesystem)
  # Size should be in GB (number), convert from string if needed
  disk {
    datastore_id = var.storage
    size         = try(tonumber(replace(var.disk_size, "G", "")), 8)
  }

  # Initialization block for hostname and IP configuration
  initialization {
    hostname = var.name

    # IP configuration - static IP if provided, otherwise DHCP
    dynamic "ip_config" {
      for_each = var.ip_address != null ? [1] : []
      content {
        ipv4 {
          address = "${var.ip_address}/${var.prefix_length}"
          gateway = var.gateway
        }
      }
    }
  }

  # Network interface configuration
  network_interface {
    name    = "eth0" # Must match NixOS config (modules/profiles/networking-common.nix)
    bridge  = var.bridge
    enabled = true
  }

  # Operating system template
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

  # Lifecycle configuration
  # Note: prevent_destroy must be a static value, cannot use variables
  # Set to true manually when needed for production containers
  lifecycle {
    prevent_destroy = false
  }
}

