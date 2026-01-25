# Root module - orchestrates all infrastructure components
#
# This is the entry point for the Terraform configuration. It orchestrates
# all infrastructure components by calling child modules and managing
# resources at the root level.
#
# Structure:
#   - Module calls: Child modules for resource creation
#   - Data sources: Read-only queries (see data-sources.tf)
#   - Locals: Computed values (see locals.tf)
#   - Variables: Input parameters (see variables.tf)
#   - Outputs: Exposed values (see outputs.tf)
#
# Usage:
#   terraform init    # Initialize providers and modules
#   terraform plan    # Preview changes
#   terraform apply   # Apply configuration

# ============================================================================
# Resource Pool Module
# ============================================================================

# Creates Proxmox resource pools for organizing services by category
# Resource pools help group related services together for easier management
# and resource allocation in Proxmox.
module "resource_pools" {
  source = "./resources"

  resource_pools = local.resource_pools
}

# ============================================================================
# PiHole-1 Container
# ============================================================================

# Upload pihole-1 NixOS image to Proxmox
module "pihole_image" {
  source        = "./modules/image-upload"
  node_name     = local.node_name
  instance_name = "pihole-1"
  image_type    = "lxc"
  storage       = "skrzynia-main" # Storage that supports vztmpl
}

# Create pihole-1 LXC container
module "pihole_instance" {
  source        = "./modules/proxmox-lxc"
  name          = "pihole-1"
  node_name     = local.node_name
  description   = local.services["pihole-1"].description
  cores         = local.services["pihole-1"].cores
  memory        = local.services["pihole-1"].memory
  disk_size     = local.services["pihole-1"].disk_size
  storage       = local.services["pihole-1"].storage
  bridge        = local.network.bridge
  pool_id       = local.services["pihole-1"].pool
  image_file_id = module.pihole_image.file_id
  ip_address    = local.services["pihole-1"].ip_address
  prefix_length = local.network.prefix_length
  gateway       = local.network.gateway
  tags          = local.services["pihole-1"].tags

  # Only nesting is allowed for non-root API tokens
  features = {
    nesting = true
    keyctl  = false
  }
}

# ============================================================================
# Caddy-1 Container
# ============================================================================

# Upload caddy-1 NixOS image to Proxmox
module "caddy_image" {
  source        = "./modules/image-upload"
  node_name     = local.node_name
  instance_name = "caddy-1"
  image_type    = "lxc"
  storage       = "skrzynia-main" # Storage that supports vztmpl
}

# Create caddy-1 LXC container
module "caddy_instance" {
  source        = "./modules/proxmox-lxc"
  name          = "caddy-1"
  node_name     = local.node_name
  description   = local.services["caddy-1"].description
  cores         = local.services["caddy-1"].cores
  memory        = local.services["caddy-1"].memory
  disk_size     = local.services["caddy-1"].disk_size
  storage       = local.services["caddy-1"].storage
  bridge        = local.network.bridge
  pool_id       = local.services["caddy-1"].pool
  image_file_id = module.caddy_image.file_id
  ip_address    = local.services["caddy-1"].ip_address
  prefix_length = local.network.prefix_length
  gateway       = local.network.gateway
  tags          = local.services["caddy-1"].tags

  # Only nesting is allowed for non-root API tokens
  features = {
    nesting = true
    keyctl  = false
  }
}

# ============================================================================
# Prometheus-1 Container
# ============================================================================

# Upload prometheus-1 NixOS image to Proxmox
module "prometheus_image" {
  source        = "./modules/image-upload"
  node_name     = local.node_name
  instance_name = "prometheus-1"
  image_type    = "lxc"
  storage       = "skrzynia-main" # Storage that supports vztmpl
}

# Create prometheus-1 LXC container
module "prometheus_instance" {
  source        = "./modules/proxmox-lxc"
  name          = "prometheus-1"
  node_name     = local.node_name
  description   = local.services["prometheus-1"].description
  cores         = local.services["prometheus-1"].cores
  memory        = local.services["prometheus-1"].memory
  disk_size     = local.services["prometheus-1"].disk_size
  storage       = local.services["prometheus-1"].storage
  bridge        = local.network.bridge
  pool_id       = local.services["prometheus-1"].pool
  image_file_id = module.prometheus_image.file_id
  ip_address    = local.services["prometheus-1"].ip_address
  prefix_length = local.network.prefix_length
  gateway       = local.network.gateway
  tags          = local.services["prometheus-1"].tags

  # Only nesting is allowed for non-root API tokens
  features = {
    nesting = true
    keyctl  = false
  }
}

# ============================================================================
# grafana-1 Container
# ============================================================================

# Upload grafana-1 NixOS image to Proxmox
module "grafana_image" {
  source        = "./modules/image-upload"
  node_name     = local.node_name
  instance_name = "grafana-1"
  image_type    = "lxc"
  storage       = "skrzynia-main" # Storage that supports vztmpl
}

# Create grafana-1 LXC container
module "grafana_instance" {
  source        = "./modules/proxmox-lxc"
  name          = "grafana-1"
  node_name     = local.node_name
  description   = local.services["grafana-1"].description
  cores         = local.services["grafana-1"].cores
  memory        = local.services["grafana-1"].memory
  disk_size     = local.services["grafana-1"].disk_size
  storage       = local.services["grafana-1"].storage
  bridge        = local.network.bridge
  pool_id       = local.services["grafana-1"].pool
  image_file_id = module.grafana_image.file_id
  ip_address    = local.services["grafana-1"].ip_address
  prefix_length = local.network.prefix_length
  gateway       = local.network.gateway
  tags          = local.services["grafana-1"].tags

  # Only nesting is allowed for non-root API tokens
  features = {
    nesting = true
    keyctl  = false
  }
}
