# Restore VM from vma.zst backup file and manage with provider
# Note: The provider doesn't have direct support for restoring from vma.zst backups,
# so we use SSH for the restore step, then manage with the provider

# Get next available VMID via SSH (provider may not have this data source)
resource "null_resource" "get_next_id" {
  provisioner "local-exec" {
    command = "ssh root@${var.node_name} 'pvesh get /cluster/nextid' > /tmp/vmid-${replace(var.name, "-", "_")}.txt"
  }
  triggers = {
    name = var.name
  }
}

locals {
  vm_id = var.vm_id != null ? var.vm_id : try(trimspace(file("/tmp/vmid-${replace(var.name, "-", "_")}.txt")), null)
}

# Restore VM from backup file (requires SSH access)
resource "null_resource" "restore_vm" {
  depends_on = [null_resource.get_next_id]

  provisioner "local-exec" {
    command = <<-EOT
      ssh root@${var.node_name} "qmrestore '${var.image_file_id}' ${local.vm_id} --storage ${var.storage}"
    EOT
  }

  triggers = {
    image_file_id = var.image_file_id
    vm_id         = local.vm_id
  }
}

# Configure and manage the VM using the provider
resource "proxmox_virtual_environment_vm" "vm" {
  depends_on = [null_resource.restore_vm]

  node_name = var.node_name
  vm_id     = local.vm_id
  name      = var.name
  tags      = concat(["nixos", "linux"], var.tags)
  pool_id   = var.pool_id

  description = var.description

  # CPU configuration
  cpu {
    cores   = var.cores
    sockets = var.sockets
    type    = var.cpu_type
  }

  # Memory configuration
  memory {
    dedicated = var.memory
  }

  # Network configuration
  network_device {
    bridge = var.bridge
  }

  # BIOS configuration
  bios = var.bios

  # Initialization block (optional - for hostname, SSH keys, etc.)
  # Note: For VMs restored from backups, hostname is typically set in the backup
  # This block can be used to override or set additional initialization settings
  initialization {
    hostname = var.name
  }

  # Operating system
  operating_system {
    type = "l26" # Linux 2.6+
  }

  # Start VM after creation
  started = var.start_on_create

  # Lifecycle: prevent destruction of running VMs
  lifecycle {
    prevent_destroy = var.prevent_destroy
    ignore_changes = [
      # Ignore changes to disk configuration since it's restored from backup
      disk,
    ]
  }
}
