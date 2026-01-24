# NixOS Proxmox Infrastructure

Declarative NixOS configuration for managing Proxmox VMs and LXC containers.

## Quick Start

### New VM

```bash
# 1. Create VM structure
make new HOST=web-1

# 2. Configure (edit hosts/web-1/configuration.nix and proxmox.nix)
# Set IP, services, Proxmox node, resources

# 3. Create VM on Proxmox
make proxmox-create HOST=web-1

# 4. Bootstrap secrets (one-time)
make bootstrap HOST=web-1 IP=10.0.0.69

# 5. Deploy configuration
make deploy HOST=web-1
```

### New Container

```bash
# 1. Create container structure
make new-container CONTAINER=app-1

# 2. Configure (edit containers/app-1/configuration.nix and proxmox.nix)

# 3. Create container on Proxmox
make proxmox-create-container CONTAINER=app-1

# 4. Bootstrap secrets (one-time)
make bootstrap-container CONTAINER=app-1 IP=10.0.0.100

# 5. Deploy configuration
make deploy-container CONTAINER=app-1
```

### Update Existing System

```bash
# Edit configuration, then deploy
make deploy HOST=web-1
# or
make deploy-container CONTAINER=app-1
```

## Commands

### VMs
- `make new HOST=<name>` - Create VM structure
- `make proxmox-create HOST=<name>` - Build and create VM
- `make bootstrap HOST=<name> IP=<ip>` - Bootstrap secrets (one-time)
- `make deploy HOST=<name>` - Deploy configuration

### Containers
- `make new-container CONTAINER=<name>` - Create container structure
- `make proxmox-create-container CONTAINER=<name>` - Build and create container
- `make bootstrap-container CONTAINER=<name> IP=<ip>` - Bootstrap secrets (one-time)
- `make deploy-container CONTAINER=<name>` - Deploy configuration

### Common
- `make deploy-all` - Deploy to all systems
- `make check` - Validate configuration

## Configuration

### VM Example (`hosts/web-1/configuration.nix`)

```nix
{
  imports = [
    ../../modules/platform/proxmox.nix
    ../../modules/base/defaults.nix
    ../../modules/profiles/static-ip.nix
    ./secrets.nix
  ];

  my.networking.staticIPv4 = {
    enable = true;
    address = "10.0.0.69";
    gateway = "10.0.0.1";
  };
}
```

### Container Example (`containers/app-1/configuration.nix`)

```nix
{
  imports = [
    ../../modules/platform/proxmox-lxc.nix
    ../../modules/base/defaults.nix
    ../../modules/profiles/static-ip.nix
    ./secrets.nix
  ];

  my.networking.staticIPv4 = {
    enable = true;
    address = "10.0.0.100";
    gateway = "10.0.0.1";
  };
}
```

### Proxmox Metadata

**VM** (`hosts/web-1/proxmox.nix`):
```nix
{
  node = "10.0.0.50";
  cores = 2;
  memory = 2048;
  bridge = "vmbr0";
}
```

**Container** (`containers/app-1/proxmox.nix`):
```nix
{
  node = "10.0.0.50";
  cores = 1;
  memory = 512;
  bridge = "vmbr0";
  unprivileged = true;
  features = [ "nesting=1" "keyctl=1" ];
  rootfsSize = "4G";
}
```

## Secrets

Secrets are managed with sops-nix + age. See [SECRETS.md](./SECRETS.md) for details.

```bash
# Edit secrets
sops secrets/hosts/web-1.yaml

# Bootstrap age key (one-time per system)
make bootstrap HOST=web-1 IP=10.0.0.69
```
