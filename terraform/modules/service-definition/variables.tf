variable "service_name" {
  description = "Service name (must exist in locals.services)"
  type        = string
}

variable "services" {
  description = "Services map from locals.services"
  type = map(object({
    ip_address  = string
    category    = string
    pool        = string
    type        = string
    cores       = number
    memory      = number
    disk_size   = any
    storage     = string
    description = string
    subdomain   = string
    tags        = list(string)
  }))
}

variable "network" {
  description = "Network configuration from locals.network"
  type = object({
    gateway       = string
    prefix_length = number
    bridge        = string
    dns_server    = string
  })
}

