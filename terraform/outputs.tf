# Output all VM/container IDs for reference
output "vm_ids" {
  description = "Map of VM/container names to IDs"
  value       = {}
  # This will be populated by individual instance modules
}

