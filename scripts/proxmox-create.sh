#!/usr/bin/env bash
set -euo pipefail

HOST="$1"

# ---- Read Proxmox metadata via Nix
META=$(nix eval --json ".#proxmox.${HOST}")

NODE=$(jq -r '.node' <<<"$META")
CORES=$(jq -r '.cores // 1' <<<"$META")
MEMORY=$(jq -r '.memory // 1024' <<<"$META")
BRIDGE=$(jq -r '.bridge // "vmbr0"' <<<"$META")

# ---- Locate built image
IMAGE_LOCAL=$(ls result/*.vma.zst | head -n1)
IMAGE_NAME=$(basename "$IMAGE_LOCAL")
IMAGE_REMOTE="/var/lib/vz/dump/$IMAGE_NAME"

echo "Using image: $IMAGE_LOCAL"
echo "Target node: $NODE"

# ---- Upload image (resumable, safe)
echo "Uploading image to Proxmox..."
rsync -avP \
  "$IMAGE_LOCAL" \
  root@"$NODE":"$IMAGE_REMOTE"

# ---- Allocate VMID safely
echo "Fetching free VMID from Proxmox..."
VMID=$(ssh root@"$NODE" pvesh get /cluster/nextid)

echo "Assigned VMID: $VMID"

# ---- Restore and configure VM
ssh root@"$NODE" <<EOF
set -e

qmrestore "$IMAGE_REMOTE" $VMID --storage local-lvm

qm set $VMID \
  --name $HOST \
  --cores $CORES \
  --memory $MEMORY \
  --net0 virtio,bridge=$BRIDGE \
  --tags nixos,linux \
  --ostype nixos

qm start $VMID
EOF

echo "VM '$HOST' created successfully (VMID $VMID)"

