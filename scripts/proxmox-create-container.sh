#!/usr/bin/env bash
set -euo pipefail

CONTAINER="$1"

# ---- Read Proxmox metadata via Nix
META=$(nix eval --json ".#proxmoxContainers.${CONTAINER}")

NODE=$(jq -r '.node' <<<"$META")
CORES=$(jq -r '.cores // 1' <<<"$META")
MEMORY=$(jq -r '.memory // 1024' <<<"$META")
BRIDGE=$(jq -r '.bridge // "vmbr0"' <<<"$META")
UNPRIVILEGED=$(jq -r '.unprivileged // true' <<<"$META")

# ---- Read network configuration from NixOS config
NETWORK_CONFIG=$(nix eval --json ".#nixosConfigurations.${CONTAINER}.config.my.networking.staticIPv4")
IP=$(jq -r '.address // empty' <<<"$NETWORK_CONFIG")
PREFIX_LENGTH=$(jq -r '.prefixLength // 24' <<<"$NETWORK_CONFIG")
GATEWAY=$(jq -r '.gateway // empty' <<<"$NETWORK_CONFIG")
# Handle features as array or string
FEATURES=$(jq -r '
  if .features == null then "nesting=1,keyctl=1"
  elif (.features | type) == "array" then (.features | join(","))
  else .features
  end' <<<"$META")
ROOTFS_SIZE_RAW=$(jq -r '.rootfsSize // "8G"' <<<"$META")
# Convert "8G" or "8GB" to "8" for Proxmox (it expects just the number)
ROOTFS_SIZE=$(echo "$ROOTFS_SIZE_RAW" | sed 's/[^0-9]//g')
STORAGE=$(jq -r '.storage // "local-lvm"' <<<"$META")

# Build network interface configuration
# Combine IP and prefixLength into CIDR notation for Proxmox
if [ -n "$IP" ] && [ -n "$GATEWAY" ]; then
  IP_CIDR="${IP}/${PREFIX_LENGTH}"
  NET_CONFIG="name=eth0,bridge=$BRIDGE,ip=$IP_CIDR,gw=$GATEWAY"
else
  NET_CONFIG="name=eth0,bridge=$BRIDGE"
fi

# ---- Locate built image
IMAGE_LOCAL=$(ls results/${CONTAINER}/result/tarball/*.tar.xz 2>/dev/null | head -n1)
if [ -z "$IMAGE_LOCAL" ]; then
  # Fallback to result symlink for backwards compatibility
  IMAGE_LOCAL=$(ls result/tarball/*.tar.xz 2>/dev/null | head -n1)
fi
if [ -z "$IMAGE_LOCAL" ]; then
  echo "Error: No image found. Run 'just image-container ${CONTAINER}' first."
  exit 1
fi
IMAGE_NAME=$(basename "$IMAGE_LOCAL")
IMAGE_REMOTE="/var/lib/vz/template/cache/$IMAGE_NAME"

echo "Using image: $IMAGE_LOCAL"
echo "Target node: $NODE"

# ---- Upload image (resumable, safe)
echo "Uploading image to Proxmox..."
rsync -avP \
  "$IMAGE_LOCAL" \
  root@"$NODE":"$IMAGE_REMOTE"

# ---- Allocate CTID safely
echo "Fetching free CTID from Proxmox..."
CTID=$(ssh root@"$NODE" pvesh get /cluster/nextid)

echo "Assigned CTID: $CTID"

# ---- Create and configure container
ssh root@"$NODE" <<EOF
set -e

pct create $CTID "$IMAGE_REMOTE" \
  --unprivileged $UNPRIVILEGED \
  --features $FEATURES \
  --rootfs $STORAGE:$ROOTFS_SIZE \
  --net0 "$NET_CONFIG" \
  --ostype unmanaged \
  --cores $CORES \
  --memory $MEMORY \
  --tags nixos,linux,lxc \
  --console 1 \
  --cmode tty

pct set $CTID --hostname $CONTAINER

pct start $CTID

# Wait for container to be ready
echo "Waiting for container to initialize..."
sleep 5
EOF

# Extract IP without CIDR for display
IP_DISPLAY=$(echo "$IP" | cut -d'/' -f1 2>/dev/null || echo "$IP")
echo "Container '$CONTAINER' created successfully (CTID $CTID)"
if [ -n "$IP_DISPLAY" ]; then
  echo "You can now SSH into it: ssh ops@$IP_DISPLAY"
fi

