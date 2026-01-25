variable "resource_pools" {
  description = "Resource pools configuration with optional resource limits"
  type = map(object({
    comment       = string
    memory_limit  = optional(number) # Memory limit in MB
    cpu_limit     = optional(number) # CPU cores limit
    disk_limit_gb = optional(number) # Disk limit in GB
  }))
}


