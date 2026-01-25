# Output existing containers from Proxmox
output "existing_containers" {
  description = "List of existing containers on the Proxmox node"
  value       = data.proxmox_virtual_environment_containers.all.containers
}

output "existing_container_ids" {
  description = "List of existing container VM IDs"
  value       = [for container in data.proxmox_virtual_environment_containers.all.containers : container.vm_id]
}

# Output existing VMs from Proxmox
output "existing_vms" {
  description = "List of existing VMs on the Proxmox node"
  value       = data.proxmox_virtual_environment_vms.all.vms
}

output "existing_vm_ids" {
  description = "List of existing VM IDs"
  value       = [for vm in data.proxmox_virtual_environment_vms.all.vms : vm.vm_id]
}

# Output available datastores
output "available_datastores" {
  description = "List of available datastores/storage pools"
  value       = data.proxmox_virtual_environment_datastores.all.datastores
}

