HOST ?=
SSH_USER ?= ops
SYSTEM ?= x86_64-linux

.PHONY: help
help:
	@echo "Available targets:"
	@echo "  make new HOST=web-2"
	@echo "  make image HOST=web-2"
	@echo "  make bootstrap HOST=web-2 IP=10.0.0.20"
	@echo "  make deploy HOST=web-2"
	@echo "  make deploy-all"
	@echo "  make check"
	@echo "  make proxmox-create HOST=web-2"

## 1️⃣ Declare a new VM
.PHONY: new
new:
	@test -n "$(HOST)" || (echo "HOST required"; exit 1)
	mkdir -p hosts/$(HOST)
	cp hosts/template/configuration.nix hosts/$(HOST)/configuration.nix
	cp hosts/template/proxmox.nix hosts/$(HOST)/proxmox.nix
	cp hosts/template/secrets.nix hosts/$(HOST)/secrets.nix
	sops secrets/hosts/$(HOST).yaml

## 2️⃣ Build Proxmox image
.PHONY: image
image:
	@test -n "$(HOST)" || (echo "HOST required"; exit 1)
	nix build .#$(HOST)

## 3️⃣ Bootstrap sops key (one-time)
.PHONY: bootstrap
bootstrap:
	@test -n "$(HOST)" || (echo "HOST required"; exit 1)
	@test -n "$(IP)" || (echo "IP required"; exit 1)
	ssh $(SSH_USER)@$(IP) "sudo install -d -m 0700 /var/lib/sops-nix"
	scp ~/.config/sops/age/keys.txt $(SSH_USER)@$(IP):/tmp/age.key
	ssh $(SSH_USER)@$(IP) "sudo install -m 0400 /tmp/age.key /var/lib/sops-nix/key.txt && rm /tmp/age.key"

## 4️⃣ Deploy configuration
.PHONY: deploy
deploy:
	@test -n "$(HOST)" || (echo "HOST required"; exit 1)
	nix run github:serokell/deploy-rs -- .#$(HOST)

.PHONY: deploy-all
deploy-all:
	@echo "Deploying to all hosts..."
	@nix run github:serokell/deploy-rs -- . || \
	  (echo "Deploy failed. No changes rolled back automatically."; exit 1)

## 5 Nix check
.PHONY: check
check:
	nix flake check
	nix eval .#deploy.nodes >/dev/null

## 6 proxmox create
.PHONY: proxmox-create
proxmox-create:
	@test -n "$(HOST)" || (echo "HOST required"; exit 1)
	nix build .#$(HOST)
	./scripts/proxmox-create.sh $(HOST)
