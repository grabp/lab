# NixOS Proxmox Infrastructure

Declarative NixOS configuration for managing Proxmox VMs and LXC containers.

## Quick Start

### New VM

```bash
# 1. Create VM structure
just new web-1

# 2. Configure (edit vms/web-1/configuration.nix and proxmox.nix)
# Set IP, services, Proxmox node, resources

# 3. Create VM on Proxmox
just proxmox-create web-1

# 4. Bootstrap secrets (one-time)
just bootstrap web-1 10.0.0.69

# 5. Deploy configuration
just deploy web-1
```

### New Container

```bash
# 1. Create container structure
just new-container app-1

# 2. Configure (edit containers/app-1/configuration.nix and proxmox.nix)

# 3. Create container on Proxmox
just proxmox-create-container app-1

# 4. Bootstrap secrets (one-time)
just bootstrap-container app-1 10.0.0.100

# 5. Deploy configuration
just deploy-container app-1
```

### Update Existing System

```bash
# Deploy configuration
just deploy web-1
# or
just deploy-container app-1

# Check system health
just health web-1
just status web-1
```

### Common Operations

```bash
# List all systems
just list

# Check all systems are reachable
just health-all

# SSH into a system (IP auto-detected)
just ssh web-1

# View configuration
just show-config web-1

# Clone a configuration
just clone web-1 web-2

# Clean up build artifacts
just clean

# Run garbage collection everywhere
just gc-all
```

## Commands

### VMs

**Setup:**
- `just new <name>` - Create VM structure from template
- `just image <name>` - Build Proxmox VM image
- `just proxmox-create <name>` - Build and create VM on Proxmox
- `just bootstrap <name> <ip>` - Bootstrap secrets (one-time)

**Deployment:**
- `just deploy <name>` - Deploy configuration to VM

**Management:**
- `just ssh <name>` - SSH into VM (auto-detects IP)
- `just health <name>` - Check VM connectivity
- `just status <name>` - Show failed systemd units
- `just show-config <name>` - Display VM configuration as JSON
- `just rotate-secrets <name> <ip>` - Re-bootstrap age keys
- `just clone <name> <new>` - Clone VM configuration
- `just remove <name> FORCE=1` - Remove VM configuration

### Containers

**Setup:**
- `just new-container <name>` - Create container structure from template
- `just image-container <name>` - Build Proxmox container image
- `just proxmox-create-container <name>` - Build and create container on Proxmox
- `just bootstrap-container <name> <ip>` - Bootstrap secrets (one-time)

**Deployment:**
- `just deploy-container <name>` - Deploy configuration to container

**Management:**
- `just ssh-container <name>` - SSH into container (auto-detects IP)
- `just health-container <name>` - Check container connectivity
- `just status-container <name>` - Show failed systemd units
- `just show-config-container <name>` - Display container configuration as JSON
- `just rotate-secrets-container <name> <ip>` - Re-bootstrap age keys
- `just clone-container <name> <new>` - Clone container configuration
- `just remove-container <name> FORCE=1` - Remove container configuration

### Common Commands

**Information:**
- `just list` - List all VMs and containers
- `just list-vms` - List all VMs
- `just list-containers` - List all containers
- `just docs` - Generate HOSTS.md with all hosts and their IPs

**Deployment:**
- `just deploy-all` - Deploy to all systems

**Validation:**
- `just check` - Validate flake configuration
- `just lint` - Alias for `check`
- `just fmt` - Format all Nix files (requires formatter in flake.nix)

**Pre-commit Hooks:**
- Pre-commit hooks automatically run on commit to:
  - Generate documentation (`just docs`)
  - Validate Nix flake (`just check`)
  - Format Nix files (nixpkgs-fmt)

  Setup:
  ```bash
  # Enter development shell (includes pre-commit)
  nix develop

  # Install git hooks
  pre-commit install

  # Or run manually
  pre-commit run --all-files
  ```

**Maintenance:**
- `just health-all` - Check connectivity for all VMs and containers
- `just gc` - Run garbage collection locally
- `just gc-all` - Run garbage collection locally and on all remote systems
- `just clean` - Remove build artifacts (result symlinks)

**Help:**
- `just` - Show all available commands (default command)

## Configuration

### VM Example (`vms/web-1/configuration.nix`)

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

**VM** (`vms/web-1/proxmox.nix`):
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

Secrets are managed with sops-nix + age. See [docs/secrets.md](./docs/secrets.md) for details.

```bash
# Edit secrets
sops secrets/vms/web-1.yaml

# Bootstrap age key (one-time per system)
just bootstrap web-1 10.0.0.69
```
