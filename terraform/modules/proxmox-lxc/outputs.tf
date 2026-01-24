output "vm_id" {
  description = "Container ID"
  value       = proxmox_virtual_environment_container.lxc.vm_id
}

output "name" {
  description = "Container name"
  value       = proxmox_virtual_environment_container.lxc.name
}

output "ipv4_addresses" {
  description = "IPv4 addresses"
  value       = proxmox_virtual_environment_container.lxc.ipv4_addresses
}

