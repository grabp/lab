# NixOS Infrastructure Justfile
# Variables with defaults
SSH_USER := "ops"
SYSTEM := "x86_64-linux"
AGE_KEY_PATH := env_var("HOME") + "/.config/sops/age/keys.txt"
SOPS_KEY_PATH := "/var/lib/sops-nix/key.txt"

# Default command: show available commands and current state
default:
    #!/usr/bin/env bash
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                 NixOS Infrastructure Justfile                    ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Show current systems
    echo "📊 Current Systems:"
    VMS=$(ls -1 vms/ 2>/dev/null | grep -v template || true)
    CONTAINERS=$(ls -1 containers/ 2>/dev/null | grep -v template || true)
    
    if [ -n "$VMS" ] || [ -n "$CONTAINERS" ]; then
        if [ -n "$VMS" ]; then
            echo "  VMs: $(echo "$VMS" | tr '\n' ' ' | sed 's/ $//')"
        else
            echo "  VMs: (none)"
        fi
        if [ -n "$CONTAINERS" ]; then
            echo "  Containers: $(echo "$CONTAINERS" | tr '\n' ' ' | sed 's/ $//')"
        else
            echo "  Containers: (none)"
        fi
    else
        echo "  No systems configured yet"
    fi
    echo ""
    
    echo "📦 VM Commands:"
    echo "  new, n <HOST> | image, i <HOST> | proxmox-create, p <HOST> | bootstrap, b <HOST> <IP>"
    echo "  deploy, d <HOST> | ssh, s <HOST> | health, h <HOST> | status <HOST>"
    echo "  show-config <HOST> | rotate-secrets <HOST> <IP> | clone <HOST> <NEW_HOST> | remove, rm <HOST> FORCE=1"
    echo ""
    
    echo "🐳 Container Commands:"
    echo "  new-container, nc <CONTAINER> | image-container, ic <CONTAINER> | proxmox-create-container, pc <CONTAINER>"
    echo "  bootstrap-container, bc <CONTAINER> <IP> | deploy-container, dc <CONTAINER> | ssh-container, sc <CONTAINER>"
    echo "  health-container, hc <CONTAINER> | status-container, status-c <CONTAINER> | show-config-container, show-c <CONTAINER>"
    echo "  rotate-secrets-container, rotate-c <CONTAINER> <IP> | clone-container, clone-c <CONTAINER> <NEW_CONTAINER>"
    echo "  remove-container, rm-c <CONTAINER> FORCE=1"
    echo ""
    
    echo "🔧 Common:"
    echo "  list, l | list-vms | list-containers | deploy-all | health-all | docs"
    echo "  check, c, lint | fmt | gc | gc-all | clean"
    echo ""
    
    echo "💡 Examples: just deploy web-1 | just ssh web-1 | just bootstrap web-1 10.0.0.69"
    echo "📖 More: just --help <command> | just --list | just --show <command>"

# Helper function for bootstrap SOPS keys
bootstrap-sops IP:
    #!/usr/bin/env bash
    ssh {{SSH_USER}}@{{IP}} "sudo install -d -m 0700 /var/lib/sops-nix"
    scp {{AGE_KEY_PATH}} {{SSH_USER}}@{{IP}}:/tmp/age.key
    ssh {{SSH_USER}}@{{IP}} "sudo install -m 0400 /tmp/age.key {{SOPS_KEY_PATH}} && rm /tmp/age.key"

#==============================================================================
# VM Commands
#==============================================================================

# Create new VM configuration
new HOST:
    #!/usr/bin/env bash
    test -n "{{HOST}}" || { echo "HOST required"; exit 1; }
    mkdir -p vms/{{HOST}}
    cp vms/template/*.nix vms/{{HOST}}/
    sops secrets/vms/{{HOST}}.yaml

# Build VM system image
image HOST:
    #!/usr/bin/env bash
    test -n "{{HOST}}" || { echo "HOST required"; exit 1; }
    nix build .#{{HOST}}

# Bootstrap SOPS keys (requires IP)
bootstrap HOST IP:
    #!/usr/bin/env bash
    test -n "{{HOST}}" || { echo "HOST required"; exit 1; }
    test -n "{{IP}}" || { echo "IP required"; exit 1; }
    ssh {{SSH_USER}}@{{IP}} "sudo install -d -m 0700 /var/lib/sops-nix"
    scp {{AGE_KEY_PATH}} {{SSH_USER}}@{{IP}}:/tmp/age.key
    ssh {{SSH_USER}}@{{IP}} "sudo install -m 0400 /tmp/age.key {{SOPS_KEY_PATH}} && rm /tmp/age.key"

# Deploy configuration to VM
deploy HOST:
    #!/usr/bin/env bash
    test -n "{{HOST}}" || { echo "HOST required"; exit 1; }
    nix run github:serokell/deploy-rs -- .#{{HOST}}

# Create VM in Proxmox
proxmox-create HOST:
    #!/usr/bin/env bash
    test -n "{{HOST}}" || { echo "HOST required"; exit 1; }
    nix build .#{{HOST}}
    ./scripts/proxmox-create.sh {{HOST}}

# SSH into VM (auto-detects IP)
ssh HOST:
    #!/usr/bin/env bash
    test -n "{{HOST}}" || { echo "HOST required"; exit 1; }
    IP=$(nix eval --json ".#nixosConfigurations.{{HOST}}.config.my.networking.staticIPv4" 2>/dev/null | jq -r '.address // empty' || echo "{{HOST}}")
    if [ -z "$IP" ] || [ "$IP" = "{{HOST}}" ]; then
        echo "Error: Could not determine IP address for {{HOST}}"
        exit 1
    fi
    ssh {{SSH_USER}}@$IP

# Check VM reachability
health HOST:
    #!/usr/bin/env bash
    test -n "{{HOST}}" || { echo "HOST required"; exit 1; }
    IP=$(nix eval --json ".#nixosConfigurations.{{HOST}}.config.my.networking.staticIPv4" 2>/dev/null | jq -r '.address // empty' || echo "")
    if [ -z "$IP" ] || [ "$IP" = "{{HOST}}" ]; then
        echo "✗ {{HOST}} (no IP configured)"
        exit 1
    fi
    if ping -c 1 -W 2 $IP >/dev/null 2>&1; then
        echo "✓ {{HOST}} ($IP) is reachable"
    else
        echo "✗ {{HOST}} ($IP) is unreachable"
        exit 1
    fi

# Show failed systemd units
status HOST:
    #!/usr/bin/env bash
    test -n "{{HOST}}" || { echo "HOST required"; exit 1; }
    IP=$(nix eval --json ".#nixosConfigurations.{{HOST}}.config.my.networking.staticIPv4" 2>/dev/null | jq -r '.address // empty' || echo "")
    if [ -z "$IP" ] || [ "$IP" = "{{HOST}}" ]; then
        echo "Error: Could not determine IP address for {{HOST}}"
        exit 1
    fi
    ssh {{SSH_USER}}@$IP "systemctl list-units --failed --no-pager" || true

# Rotate SOPS keys
rotate-secrets HOST IP:
    #!/usr/bin/env bash
    test -n "{{HOST}}" || { echo "HOST required"; exit 1; }
    test -n "{{IP}}" || { echo "IP required"; exit 1; }
    echo "Rotating secrets for {{HOST}}..."
    ssh {{SSH_USER}}@{{IP}} "sudo install -d -m 0700 /var/lib/sops-nix"
    scp {{AGE_KEY_PATH}} {{SSH_USER}}@{{IP}}:/tmp/age.key
    ssh {{SSH_USER}}@{{IP}} "sudo install -m 0400 /tmp/age.key {{SOPS_KEY_PATH}} && rm /tmp/age.key"
    echo "Secrets rotated. Deploy to apply: just deploy {{HOST}}"

# Show full NixOS configuration
show-config HOST:
    #!/usr/bin/env bash
    test -n "{{HOST}}" || { echo "HOST required"; exit 1; }
    nix eval --json .#nixosConfigurations.{{HOST}}.config | jq

# Remove VM config (requires FORCE=1)
remove HOST FORCE:
    #!/usr/bin/env bash
    test -n "{{HOST}}" || { echo "HOST required"; exit 1; }
    if [ -z "{{FORCE}}" ] || [ "{{FORCE}}" != "1" ]; then
        echo "This will remove vms/{{HOST}} and secrets/vms/{{HOST}}.yaml"
        echo "Set FORCE=1 to proceed without confirmation"
        exit 1
    fi
    rm -rf vms/{{HOST}}
    rm -f secrets/vms/{{HOST}}.yaml
    echo "Removed {{HOST}} configuration"

# Clone VM configuration
clone HOST NEW_HOST:
    #!/usr/bin/env bash
    test -n "{{HOST}}" || { echo "HOST required"; exit 1; }
    test -n "{{NEW_HOST}}" || { echo "NEW_HOST required"; exit 1; }
    if [ -d "vms/{{NEW_HOST}}" ]; then
        echo "Error: vms/{{NEW_HOST}} already exists"
        exit 1
    fi
    cp -r vms/{{HOST}} vms/{{NEW_HOST}}
    if [ -f "secrets/vms/{{HOST}}.yaml" ]; then
        cp secrets/vms/{{HOST}}.yaml secrets/vms/{{NEW_HOST}}.yaml
    fi
    echo "Cloned {{HOST}} to {{NEW_HOST}}. Edit configuration before deploying."

# VM command aliases (shorter names)
alias n := new
alias i := image
alias b := bootstrap
alias d := deploy
alias p := proxmox-create
alias s := ssh
alias h := health
alias rm := remove

#==============================================================================
# Container Commands
#==============================================================================

# Create new container configuration
new-container CONTAINER:
    #!/usr/bin/env bash
    test -n "{{CONTAINER}}" || { echo "CONTAINER required"; exit 1; }
    mkdir -p containers/{{CONTAINER}}
    cp containers/template/*.nix containers/{{CONTAINER}}/
    sops secrets/vms/{{CONTAINER}}.yaml

# Build container system image
image-container CONTAINER:
    #!/usr/bin/env bash
    test -n "{{CONTAINER}}" || { echo "CONTAINER required"; exit 1; }
    nix build .#{{CONTAINER}}

# Bootstrap SOPS keys for container (requires IP)
bootstrap-container CONTAINER IP:
    #!/usr/bin/env bash
    test -n "{{CONTAINER}}" || { echo "CONTAINER required"; exit 1; }
    test -n "{{IP}}" || { echo "IP required"; exit 1; }
    ssh {{SSH_USER}}@{{IP}} "sudo install -d -m 0700 /var/lib/sops-nix"
    scp {{AGE_KEY_PATH}} {{SSH_USER}}@{{IP}}:/tmp/age.key
    ssh {{SSH_USER}}@{{IP}} "sudo install -m 0400 /tmp/age.key {{SOPS_KEY_PATH}} && rm /tmp/age.key"

# Deploy configuration to container
deploy-container CONTAINER:
    #!/usr/bin/env bash
    test -n "{{CONTAINER}}" || { echo "CONTAINER required"; exit 1; }
    nix run github:serokell/deploy-rs -- .#{{CONTAINER}}

# Create container in Proxmox
proxmox-create-container CONTAINER:
    #!/usr/bin/env bash
    test -n "{{CONTAINER}}" || { echo "CONTAINER required"; exit 1; }
    nix build .#{{CONTAINER}}
    ./scripts/proxmox-create-container.sh {{CONTAINER}}

# SSH into container (auto-detects IP)
ssh-container CONTAINER:
    #!/usr/bin/env bash
    test -n "{{CONTAINER}}" || { echo "CONTAINER required"; exit 1; }
    IP=$(nix eval --json ".#nixosConfigurations.{{CONTAINER}}.config.my.networking.staticIPv4" 2>/dev/null | jq -r '.address // empty' || echo "{{CONTAINER}}")
    if [ -z "$IP" ] || [ "$IP" = "{{CONTAINER}}" ]; then
        echo "Error: Could not determine IP address for {{CONTAINER}}"
        exit 1
    fi
    ssh {{SSH_USER}}@$IP

# Check container reachability
health-container CONTAINER:
    #!/usr/bin/env bash
    test -n "{{CONTAINER}}" || { echo "CONTAINER required"; exit 1; }
    IP=$(nix eval --json ".#nixosConfigurations.{{CONTAINER}}.config.my.networking.staticIPv4" 2>/dev/null | jq -r '.address // empty' || echo "")
    if [ -z "$IP" ] || [ "$IP" = "{{CONTAINER}}" ]; then
        echo "✗ {{CONTAINER}} (no IP configured)"
        exit 1
    fi
    if ping -c 1 -W 2 $IP >/dev/null 2>&1; then
        echo "✓ {{CONTAINER}} ($IP) is reachable"
    else
        echo "✗ {{CONTAINER}} ($IP) is unreachable"
        exit 1
    fi

# Show failed systemd units for container
status-container CONTAINER:
    #!/usr/bin/env bash
    test -n "{{CONTAINER}}" || { echo "CONTAINER required"; exit 1; }
    IP=$(nix eval --json ".#nixosConfigurations.{{CONTAINER}}.config.my.networking.staticIPv4" 2>/dev/null | jq -r '.address // empty' || echo "")
    if [ -z "$IP" ] || [ "$IP" = "{{CONTAINER}}" ]; then
        echo "Error: Could not determine IP address for {{CONTAINER}}"
        exit 1
    fi
    ssh {{SSH_USER}}@$IP "systemctl list-units --failed --no-pager" || true

# Rotate SOPS keys for container
rotate-secrets-container CONTAINER IP:
    #!/usr/bin/env bash
    test -n "{{CONTAINER}}" || { echo "CONTAINER required"; exit 1; }
    test -n "{{IP}}" || { echo "IP required"; exit 1; }
    echo "Rotating secrets for {{CONTAINER}}..."
    ssh {{SSH_USER}}@{{IP}} "sudo install -d -m 0700 /var/lib/sops-nix"
    scp {{AGE_KEY_PATH}} {{SSH_USER}}@{{IP}}:/tmp/age.key
    ssh {{SSH_USER}}@{{IP}} "sudo install -m 0400 /tmp/age.key {{SOPS_KEY_PATH}} && rm /tmp/age.key"
    echo "Secrets rotated. Deploy to apply: just deploy-container {{CONTAINER}}"

# Show full NixOS configuration for container
show-config-container CONTAINER:
    #!/usr/bin/env bash
    test -n "{{CONTAINER}}" || { echo "CONTAINER required"; exit 1; }
    nix eval --json .#nixosConfigurations.{{CONTAINER}}.config | jq

# Remove container config (requires FORCE=1)
remove-container CONTAINER FORCE:
    #!/usr/bin/env bash
    test -n "{{CONTAINER}}" || { echo "CONTAINER required"; exit 1; }
    if [ -z "{{FORCE}}" ] || [ "{{FORCE}}" != "1" ]; then
        echo "This will remove containers/{{CONTAINER}} and secrets/vms/{{CONTAINER}}.yaml"
        echo "Set FORCE=1 to proceed without confirmation"
        exit 1
    fi
    rm -rf containers/{{CONTAINER}}
    rm -f secrets/vms/{{CONTAINER}}.yaml
    echo "Removed {{CONTAINER}} configuration"

# Clone container configuration
clone-container CONTAINER NEW_CONTAINER:
    #!/usr/bin/env bash
    test -n "{{CONTAINER}}" || { echo "CONTAINER required"; exit 1; }
    test -n "{{NEW_CONTAINER}}" || { echo "NEW_CONTAINER required"; exit 1; }
    if [ -d "containers/{{NEW_CONTAINER}}" ]; then
        echo "Error: containers/{{NEW_CONTAINER}} already exists"
        exit 1
    fi
    cp -r containers/{{CONTAINER}} containers/{{NEW_CONTAINER}}
    if [ -f "secrets/vms/{{CONTAINER}}.yaml" ]; then
        cp secrets/vms/{{CONTAINER}}.yaml secrets/vms/{{NEW_CONTAINER}}.yaml
    fi
    echo "Cloned {{CONTAINER}} to {{NEW_CONTAINER}}. Edit configuration before deploying."

# Container command aliases (shorter names)
alias nc := new-container
alias ic := image-container
alias bc := bootstrap-container
alias dc := deploy-container
alias pc := proxmox-create-container
alias sc := ssh-container
alias hc := health-container
alias rm-c := remove-container

# Additional container aliases
alias new-c := new-container
alias image-c := image-container
alias bootstrap-c := bootstrap-container
alias deploy-c := deploy-container
alias proxmox-c := proxmox-create-container
alias ssh-c := ssh-container
alias health-c := health-container
alias remove-c := remove-container

# Container aliases with -c suffix
alias status-c := status-container
alias rotate-c := rotate-secrets-container
alias show-c := show-config-container
alias clone-c := clone-container

#==============================================================================
# Common Commands
#==============================================================================

# List all VMs and containers
list:
    #!/usr/bin/env bash
    just list-vms
    just list-containers

# List VMs only
list-vms:
    #!/usr/bin/env bash
    if [ -d "vms" ]; then
        VMS=$(ls -1 vms/ 2>/dev/null | grep -v template || true)
        if [ -n "$VMS" ]; then
            echo "VMs:"
            echo "$VMS"
        else
            echo "No VMs found"
        fi
    else
        echo "No VMs found"
    fi

# List containers only
list-containers:
    #!/usr/bin/env bash
    if [ -d "containers" ]; then
        CONTAINERS=$(ls -1 containers/ 2>/dev/null | grep -v template || true)
        if [ -n "$CONTAINERS" ]; then
            echo "Containers:"
            echo "$CONTAINERS"
        else
            echo "No containers found"
        fi
    else
        echo "No containers found"
    fi

# Deploy to all systems
deploy-all:
    #!/usr/bin/env bash
    echo "Deploying to all systems..."
    nix run github:serokell/deploy-rs -- . || \
        (echo "Deploy failed. No changes rolled back automatically."; exit 1)

# Check flake and deploy configs
check:
    nix flake check
    nix eval .#deploy.nodes >/dev/null

# Format Nix code
fmt:
    #!/usr/bin/env bash
    nix fmt 2>&1 || (echo "Note: flake formatter not configured. Use 'nixpkgs-fmt' or configure formatter in flake.nix"; exit 0)

# Check health of all systems
health-all:
    #!/usr/bin/env bash
    echo "Checking VM health..."
    VMS=$(ls -1 vms/ 2>/dev/null | grep -v template || true)
    if [ -n "$VMS" ]; then
        for host in $VMS; do
            IP=$(nix eval --json ".#nixosConfigurations.$host.config.my.networking.staticIPv4" 2>/dev/null | jq -r '.address // empty' || echo "$host")
            if [ -n "$IP" ] && [ "$IP" != "$host" ]; then
                if ping -c 1 -W 2 $IP >/dev/null 2>&1; then
                    echo "✓ $host ($IP) is reachable"
                else
                    echo "✗ $host ($IP) is unreachable"
                fi || true
            else
                echo "⚠ $host (no IP configured)"
            fi
        done
    else
        echo "No VMs found"
    fi
    echo ""
    echo "Checking container health..."
    CONTAINERS=$(ls -1 containers/ 2>/dev/null | grep -v template || true)
    if [ -n "$CONTAINERS" ]; then
        for container in $CONTAINERS; do
            IP=$(nix eval --json ".#nixosConfigurations.$container.config.my.networking.staticIPv4" 2>/dev/null | jq -r '.address // empty' || echo "$container")
            if [ -n "$IP" ] && [ "$IP" != "$container" ]; then
                if ping -c 1 -W 2 $IP >/dev/null 2>&1; then
                    echo "✓ $container ($IP) is reachable"
                else
                    echo "✗ $container ($IP) is unreachable"
                fi || true
            else
                echo "⚠ $container (no IP configured)"
            fi
        done
    else
        echo "No containers found"
    fi

# Garbage collect local Nix store
gc:
    nix-collect-garbage -d

# Garbage collect on all systems
gc-all:
    #!/usr/bin/env bash
    just gc
    echo "Running garbage collection on remote systems..."
    VMS=$(ls -1 vms/ 2>/dev/null | grep -v template || true)
    if [ -n "$VMS" ]; then
        for host in $VMS; do
            IP=$(nix eval --json ".#nixosConfigurations.$host.config.my.networking.staticIPv4" 2>/dev/null | jq -r '.address // empty' || echo "")
            if [ -n "$IP" ] && [ "$IP" != "$host" ]; then
                echo "GC on $host ($IP)..."
                ssh {{SSH_USER}}@$IP "sudo nix-collect-garbage -d" || echo "  Failed to connect to $host"
            else
                echo "Skipping $host (no IP configured)"
            fi
        done
    fi
    CONTAINERS=$(ls -1 containers/ 2>/dev/null | grep -v template || true)
    if [ -n "$CONTAINERS" ]; then
        for container in $CONTAINERS; do
            IP=$(nix eval --json ".#nixosConfigurations.$container.config.my.networking.staticIPv4" 2>/dev/null | jq -r '.address // empty' || echo "")
            if [ -n "$IP" ] && [ "$IP" != "$container" ]; then
                echo "GC on $container ($IP)..."
                ssh {{SSH_USER}}@$IP "sudo nix-collect-garbage -d" || echo "  Failed to connect to $container"
            else
                echo "Skipping $container (no IP configured)"
            fi
        done
    fi

# Generate HOSTS.md documentation
docs:
    #!/usr/bin/env bash
    echo "# Hosts and Containers" > HOSTS.md
    echo "" >> HOSTS.md
    echo "Generated on $(date)" >> HOSTS.md
    echo "" >> HOSTS.md
    VMS=$(ls -1 vms/ 2>/dev/null | grep -v template || true)
    if [ -d "vms" ] && [ -n "$VMS" ]; then
        echo "## VMs" >> HOSTS.md
        echo "" >> HOSTS.md
        echo "| Host | IP Address |" >> HOSTS.md
        echo "|------|------------|" >> HOSTS.md
        for host in $VMS; do
            IP=$(nix eval --json ".#nixosConfigurations.$host.config.my.networking.staticIPv4" 2>/dev/null | jq -r '.address // empty' || echo "-")
            echo "| $host | $IP |" >> HOSTS.md
        done
        echo "" >> HOSTS.md
    fi
    CONTAINERS=$(ls -1 containers/ 2>/dev/null | grep -v template || true)
    if [ -d "containers" ] && [ -n "$CONTAINERS" ]; then
        echo "## Containers" >> HOSTS.md
        echo "" >> HOSTS.md
        echo "| Container | IP Address |" >> HOSTS.md
        echo "|-----------|------------|" >> HOSTS.md
        for container in $CONTAINERS; do
            IP=$(nix eval --json ".#nixosConfigurations.$container.config.my.networking.staticIPv4" 2>/dev/null | jq -r '.address // empty' || echo "-")
            echo "| $container | $IP |" >> HOSTS.md
        done
        echo "" >> HOSTS.md
    fi
    echo "Generated HOSTS.md"

# Remove build artifacts
clean:
    rm -f result result-*
    echo "Cleaned build artifacts"

#==============================================================================
# Terraform Commands
#==============================================================================

# Initialize Terraform
terraform-init:
    cd terraform && terraform init

# Plan Terraform changes
terraform-plan:
    cd terraform && terraform plan

# Apply Terraform changes
terraform-apply:
    cd terraform && terraform apply

# Show Terraform state
terraform-show:
    cd terraform && terraform show

# Destroy specific resource
terraform-destroy NAME:
    cd terraform && terraform destroy -target=module.{{NAME}}_instance

# Format Terraform files
terraform-fmt:
    cd terraform && terraform fmt -recursive

# Validate Terraform configuration
terraform-validate:
    cd terraform && terraform validate

# Terraform aliases
alias tf-init := terraform-init
alias tf-plan := terraform-plan
alias tf-apply := terraform-apply
alias tf-show := terraform-show
alias tf-destroy := terraform-destroy
alias tf-fmt := terraform-fmt
alias tf-validate := terraform-validate

# Common command aliases
alias l := list
alias c := check
alias lint := check

