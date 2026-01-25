output "vm_id" {
  description = "Container ID"
  value       = proxmox_virtual_environment_container.lxc.vm_id
}

output "id" {
  description = "Container resource ID"
  value       = proxmox_virtual_environment_container.lxc.id
}
