# Service definition outputs - provides validated service configuration

locals {
  service = var.services[var.service_name]

  # Validate service exists
  _validation = var.services[var.service_name] != null ? true : tobool("Service '${var.service_name}' not found in services map")
}

output "ip_address" {
  description = "Service IP address"
  value       = local.service.ip_address
}

output "gateway" {
  description = "Network gateway"
  value       = var.network.gateway
}

output "prefix_length" {
  description = "Network prefix length"
  value       = var.network.prefix_length
}

output "bridge" {
  description = "Network bridge"
  value       = var.network.bridge
}

output "pool_id" {
  description = "Resource pool ID"
  value       = local.service.pool
}

output "cores" {
  description = "CPU cores"
  value       = local.service.cores
}

output "memory" {
  description = "Memory in MB"
  value       = local.service.memory
}

output "disk_size" {
  description = "Disk size (string for containers, number for VMs)"
  value       = local.service.disk_size
}

output "storage" {
  description = "Storage pool"
  value       = local.service.storage
}

output "description" {
  description = "Service description"
  value       = local.service.description
}

output "tags" {
  description = "Service tags"
  value       = local.service.tags
}

output "type" {
  description = "Service type (container or vm)"
  value       = local.service.type
}

output "category" {
  description = "Service category"
  value       = local.service.category
}

output "subdomain" {
  description = "Service subdomain"
  value       = local.service.subdomain
}

