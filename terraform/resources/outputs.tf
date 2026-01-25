output "pool_ids" {
  description = "Map of pool IDs to pool resource addresses"
  value = {
    for pool_id, pool in proxmox_virtual_environment_pool.pools : pool_id => pool.pool_id
  }
}

