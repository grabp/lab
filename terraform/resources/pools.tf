# Proxmox resource pools for organizing services by category
# Based on ARCHITECTURE.md service groupings

resource "proxmox_virtual_environment_pool" "pools" {
  for_each = var.resource_pools

  pool_id = each.key
  comment = each.value.comment
}

