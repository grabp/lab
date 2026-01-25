# Data sources for querying existing Proxmox resources

# Query all containers on a specific node
data "proxmox_virtual_environment_containers" "all" {
  node_name = local.node_name
}

# Query all VMs on a specific node
data "proxmox_virtual_environment_vms" "all" {
  node_name = local.node_name
}

# Query available datastores/storage
data "proxmox_virtual_environment_datastores" "all" {
  node_name = local.node_name
}

# Query cluster nodes (if in a cluster)
# Uncomment if you want to query cluster nodes
# data "proxmox_virtual_environment_nodes" "all" {
#   # No node_name needed - queries all nodes in cluster
# }

