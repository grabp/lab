# Variables
HOST ?=
CONTAINER ?=
SSH_USER ?= ops
SYSTEM ?= x86_64-linux
AGE_KEY_PATH ?= ~/.config/sops/age/keys.txt
SOPS_KEY_PATH ?= /var/lib/sops-nix/key.txt

# Helper functions
check-host = @test -n "$(HOST)" || (echo "HOST required"; exit 1)
check-container = @test -n "$(CONTAINER)" || (echo "CONTAINER required"; exit 1)
check-ip = @test -n "$(IP)" || (echo "IP required"; exit 1)

# Bootstrap commands (shared between hosts and containers)
bootstrap-sops = \
	ssh $(SSH_USER)@$(IP) "sudo install -d -m 0700 /var/lib/sops-nix" && \
	scp $(AGE_KEY_PATH) $(SSH_USER)@$(IP):/tmp/age.key && \
	ssh $(SSH_USER)@$(IP) "sudo install -m 0400 /tmp/age.key $(SOPS_KEY_PATH) && rm /tmp/age.key"

#==============================================================================
# Help
#==============================================================================

.PHONY: help
help:
	@echo "Host targets:"
	@echo "  make new HOST=web-2"
	@echo "  make image HOST=web-2"
	@echo "  make bootstrap HOST=web-2 IP=10.0.0.20"
	@echo "  make deploy HOST=web-2"
	@echo "  make proxmox-create HOST=web-2"
	@echo ""
	@echo "Container targets:"
	@echo "  make new-container CONTAINER=app-1"
	@echo "  make image-container CONTAINER=app-1"
	@echo "  make bootstrap-container CONTAINER=app-1 IP=10.0.0.20"
	@echo "  make deploy-container CONTAINER=app-1"
	@echo "  make proxmox-create-container CONTAINER=app-1"
	@echo ""
	@echo "Common targets:"
	@echo "  make deploy-all"
	@echo "  make check"

#==============================================================================
# Host targets
#==============================================================================

## 1️⃣ Declare a new VM
.PHONY: new
new:
	$(check-host)
	mkdir -p hosts/$(HOST)
	cp hosts/template/*.nix hosts/$(HOST)/
	sops secrets/hosts/$(HOST).yaml

## 2️⃣ Build Proxmox image
.PHONY: image
image:
	$(check-host)
	nix build .#$(HOST)

## 3️⃣ Bootstrap sops key (one-time)
.PHONY: bootstrap
bootstrap:
	$(check-host)
	$(check-ip)
	$(bootstrap-sops)

## 4️⃣ Deploy configuration
.PHONY: deploy
deploy:
	$(check-host)
	nix run github:serokell/deploy-rs -- .#$(HOST)

## 5️⃣ Create VM on Proxmox
.PHONY: proxmox-create
proxmox-create:
	$(check-host)
	nix build .#$(HOST)
	./scripts/proxmox-create.sh $(HOST)

#==============================================================================
# Container targets
#==============================================================================

## 1️⃣ Declare a new container
.PHONY: new-container
new-container:
	$(check-container)
	mkdir -p containers/$(CONTAINER)
	cp containers/template/*.nix containers/$(CONTAINER)/
	sops secrets/hosts/$(CONTAINER).yaml

## 2️⃣ Build Proxmox container image
.PHONY: image-container
image-container:
	$(check-container)
	nix build .#$(CONTAINER)

## 3️⃣ Bootstrap sops key for container (one-time)
.PHONY: bootstrap-container
bootstrap-container:
	$(check-container)
	$(check-ip)
	$(bootstrap-sops)

## 4️⃣ Deploy container configuration
.PHONY: deploy-container
deploy-container:
	$(check-container)
	nix run github:serokell/deploy-rs -- .#$(CONTAINER)

## 5️⃣ Create container on Proxmox
.PHONY: proxmox-create-container
proxmox-create-container:
	$(check-container)
	nix build .#$(CONTAINER)
	./scripts/proxmox-create-container.sh $(CONTAINER)

#==============================================================================
# Common targets
#==============================================================================

.PHONY: deploy-all
deploy-all:
	@echo "Deploying to all hosts..."
	@nix run github:serokell/deploy-rs -- . || \
		(echo "Deploy failed. No changes rolled back automatically."; exit 1)

.PHONY: check
check:
	nix flake check
	nix eval .#deploy.nodes >/dev/null
