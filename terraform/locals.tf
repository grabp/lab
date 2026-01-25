# Local values - consolidated from across the configuration
#
# This file contains all computed values used throughout the Terraform configuration.
# Locals help avoid repetition and make the configuration more maintainable.
#
# Organization:
#   1. Authentication and provider configuration
#   2. Network configuration
#   3. Proxmox node configuration
#   4. Service registry (IP allocations and resource definitions)
#   5. Resource pool configuration
#   6. Derived/computed values

locals {
  # ============================================================================
  # Authentication and Provider Configuration
  # ============================================================================

  # Proxmox API token resolution with fallback priority
  # Priority: 1) Variable, 2) SOPS secret, 3) Environment variable, 4) null (use username/password)
  proxmox_api_token = var.proxmox_api_token != null ? var.proxmox_api_token : (
    try(data.sops_file.terraform_secrets.data["proxmox_api_token"], null) != null ?
    data.sops_file.terraform_secrets.data["proxmox_api_token"] :
    null
  )

  # ============================================================================
  # Network Configuration
  # ============================================================================

  # Network configuration consolidated from variables
  # Based on ARCHITECTURE.md network settings
  network = {
    gateway       = var.network_gateway
    prefix_length = var.network_prefix_length
    bridge        = var.default_bridge
    dns_server    = var.network_dns_server
  }

  # ============================================================================
  # Proxmox Node Configuration
  # ============================================================================

  # Resolve Proxmox node name: use explicit node_name if provided, otherwise use proxmox_host
  node_name = var.proxmox_node_name != null ? var.proxmox_node_name : var.proxmox_host

  # ============================================================================
  # Service Registry
  # ============================================================================

  # Service definitions from ARCHITECTURE.md IP allocation table
  # This is the single source of truth for all service configurations including:
  # - IP address allocations
  # - Resource requirements (CPU, memory, disk)
  # - Service categorization and tagging
  # - Network and storage configuration
  services = {
    # Infrastructure Layer
    "pihole-1" = {
      ip_address  = "10.0.0.53"
      category    = "infrastructure"
      pool        = "infrastructure"
      type        = "container"
      cores       = 1
      memory      = 512
      disk_size   = "4G"
      storage     = var.default_storage
      description = "PiHole DNS server"
      subdomain   = "pihole.grab-lab.gg"
      tags        = ["dns", "adblock"]
    }
    # TODO: Uncomment services as they are deployed
    # "caddy-1" = {
    #   ip_address  = "10.0.0.80"
    #   category    = "infrastructure"
    #   pool        = "infrastructure"
    #   type        = "container"
    #   cores       = 1
    #   memory      = 512
    #   disk_size   = "4G"
    #   storage     = var.default_storage
    #   description = "Caddy reverse proxy"
    #   subdomain   = "caddy.grab-lab.gg"
    #   tags        = ["reverse-proxy", "ssl"]
    # }
    # "netbird-1" = {
    #   ip_address  = "10.0.0.11"
    #   category    = "infrastructure"
    #   pool        = "infrastructure"
    #   type        = "container"
    #   cores       = 1
    #   memory      = 256
    #   disk_size   = "2G"
    #   storage     = var.default_storage
    #   description = "NetBird mesh VPN"
    #   subdomain   = "netbird.grab-lab.gg"
    #   tags        = ["vpn", "mesh"]
    # }

    # # Monitoring Stack
    # "prometheus-1" = {
    #   ip_address  = "10.0.0.20"
    #   category    = "monitoring"
    #   pool        = "monitoring"
    #   type        = "container"
    #   cores       = 2
    #   memory      = 1536
    #   disk_size   = "20G"
    #   storage     = var.default_storage
    #   description = "Prometheus metrics collection"
    #   subdomain   = "prometheus.grab-lab.gg"
    #   tags        = ["monitoring", "metrics"]
    # }
    # "grafana-1" = {
    #   ip_address  = "10.0.0.21"
    #   category    = "monitoring"
    #   pool        = "monitoring"
    #   type        = "container"
    #   cores       = 2
    #   memory      = 1024
    #   disk_size   = "10G"
    #   storage     = var.default_storage
    #   description = "Grafana dashboards"
    #   subdomain   = "grafana.grab-lab.gg"
    #   tags        = ["monitoring", "dashboards"]
    # }
    # "loki-1" = {
    #   ip_address  = "10.0.0.22"
    #   category    = "monitoring"
    #   pool        = "monitoring"
    #   type        = "container"
    #   cores       = 2
    #   memory      = 1536
    #   disk_size   = "20G"
    #   storage     = var.default_storage
    #   description = "Loki log aggregation"
    #   subdomain   = "loki.grab-lab.gg"
    #   tags        = ["monitoring", "logs"]
    # }

    # # Services
    # "portainer-1" = {
    #   ip_address  = "10.0.0.30"
    #   category    = "services"
    #   pool        = "services"
    #   type        = "container"
    #   cores       = 1
    #   memory      = 512
    #   disk_size   = "4G"
    #   storage     = var.default_storage
    #   description = "Portainer container management"
    #   subdomain   = "portainer.grab-lab.gg"
    #   tags        = ["management", "containers"]
    # }
    # "homeassistant-1" = {
    #   ip_address  = "10.0.0.31"
    #   category    = "services"
    #   pool        = "services"
    #   type        = "vm"
    #   cores       = 2
    #   memory      = 2048
    #   disk_size   = 32
    #   storage     = var.default_storage
    #   description = "Home Assistant home automation"
    #   subdomain   = "home.grab-lab.gg"
    #   tags        = ["automation", "iot"]
    # }
    # "uptimekuma-1" = {
    #   ip_address  = "10.0.0.32"
    #   category    = "services"
    #   pool        = "services"
    #   type        = "container"
    #   cores       = 1
    #   memory      = 512
    #   disk_size   = "4G"
    #   storage     = var.default_storage
    #   description = "UptimeKuma uptime monitoring"
    #   subdomain   = "status.grab-lab.gg"
    #   tags        = ["monitoring", "uptime"]
    # }

    # # Docker Host VM
    # "docker-1" = {
    #   ip_address  = "10.0.0.40"
    #   category    = "docker"
    #   pool        = "docker"
    #   type        = "vm"
    #   cores       = 2
    #   memory      = 2048
    #   disk_size   = 32
    #   storage     = var.default_storage
    #   description = "Docker host with Portainer agent"
    #   subdomain   = "docker.grab-lab.gg"
    #   tags        = ["docker", "portainer-agent"]
    # }
  }

  # ============================================================================
  # Resource Pool Configuration
  # ============================================================================

  # Proxmox resource pools for organizing services by category
  # These pools help group related services together for easier management
  # Includes resource limits based on ARCHITECTURE.md allocations
  resource_pools = {
    "infrastructure" = {
      comment       = "Infrastructure services: DNS, reverse proxy, VPN"
      memory_limit  = 1280 # 1.25GB in MB
      cpu_limit     = 3    # Total cores
      disk_limit_gb = 10   # Total disk in GB
    }
    "monitoring" = {
      comment       = "Monitoring stack: Prometheus, Grafana, Loki"
      memory_limit  = 4096 # 4GB
      cpu_limit     = 6
      disk_limit_gb = 50
    }
    "services" = {
      comment       = "Application services: Portainer, Home Assistant, UptimeKuma"
      memory_limit  = 3072 # 3GB
      cpu_limit     = 4
      disk_limit_gb = 40
    }
    "docker" = {
      comment       = "Docker host VM"
      memory_limit  = 2048 # 2GB
      cpu_limit     = 2
      disk_limit_gb = 32
    }
  }

  # ============================================================================
  # Derived/Computed Values
  # ============================================================================

  # IP address allocation map extracted from service registry
  # Useful for conflict detection and IP address management
  ip_allocations = {
    for name, config in local.services : name => config.ip_address
  }

  # ============================================================================
  # Pool Allocation Tracking
  # ============================================================================

  # Group services by pool for allocation calculations
  services_by_pool = {
    for pool_name, _ in local.resource_pools :
    pool_name => {
      for name, svc in local.services : name => svc if svc.pool == pool_name
    }
  }

  # Calculate current resource allocations per pool
  # Used for validation against pool limits
  # Uses coalesce with concat to handle empty service lists (sum of empty list = 0)
  pool_allocations = {
    for pool_name, services in local.services_by_pool : pool_name => {
      memory_used  = length(values(services)) > 0 ? sum([for s in values(services) : s.memory]) : 0
      cpu_used     = length(values(services)) > 0 ? sum([for s in values(services) : s.cores]) : 0
      disk_used_gb = length(values(services)) > 0 ? sum([for s in values(services) : try(tonumber(replace(tostring(s.disk_size), "G", "")), s.disk_size)]) : 0
    }
  }
}

# ============================================================================
# Pool Limit Validation Checks
# ============================================================================

# Validate that service allocations don't exceed pool limits
# These checks run during plan/apply and warn if limits are exceeded

check "pool_memory_limits" {
  assert {
    condition = alltrue([
      for pool_name, pool in local.resource_pools :
      local.pool_allocations[pool_name].memory_used <= pool.memory_limit
    ])
    error_message = "One or more pools exceed their memory limit. Check pool_allocations output for details."
  }
}

check "pool_cpu_limits" {
  assert {
    condition = alltrue([
      for pool_name, pool in local.resource_pools :
      local.pool_allocations[pool_name].cpu_used <= pool.cpu_limit
    ])
    error_message = "One or more pools exceed their CPU limit. Check pool_allocations output for details."
  }
}

check "pool_disk_limits" {
  assert {
    condition = alltrue([
      for pool_name, pool in local.resource_pools :
      local.pool_allocations[pool_name].disk_used_gb <= pool.disk_limit_gb
    ])
    error_message = "One or more pools exceed their disk limit. Check pool_allocations output for details."
  }
}