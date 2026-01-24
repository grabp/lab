#!/usr/bin/env bash
set -euo pipefail

NAME="$1"

META=$(nix eval --json ".#proxmox.${NAME}")

NODE=$(jq -r '.node' <<<"$META")
CORES=$(jq -r '.cores // 1' <<<"$META")
MEMORY=$(jq -r '.memory // 512' <<<"$META")
ROOTFS=$(jq -r '.rootfs' <<<"$META")

NET_NAME=$(jq -r '.net0.name' <<<"$META")
NET_BRIDGE=$(jq -r '.net0.bridge' <<<"$META")
NET_IP=$(jq -r '.net0.ip' <<<"$META")
NET_CIDR=$(jq -r '.net0.cidr' <<<"$META")
NET_GW=$(jq -r '.net0.gw' <<<"$META")

NET0="name=${NET_NAME},bridge=${NET_BRIDGE},ip=${NET_IP}/${NET_CIDR},gw=${NET_GW}"

IMAGE=$(ls result/tarball/*.tar.xz | head -n1)
REMOTE="/var/lib/vz/template/cache/$(basename "$IMAGE")"

echo "Uploading LXC rootfs..."
rsync -avP "$IMAGE" root@"$NODE":"$REMOTE"

CTID=$(ssh root@"$NODE" pvesh get /cluster/nextid)

echo "Creating LXC $NAME (CTID $CTID)"

ssh root@"$NODE" <<EOF
pct create $CTID $REMOTE \
  --hostname $NAME \
  --cores $CORES \
  --memory $MEMORY \
  --rootfs $ROOTFS \
  --net0 "$NET0" \
  --console 1 \
  --tags nixos,linux \
  --features keyctl=1,nesting=1 \
  --ostype nixos \
  --cmode console

pct start $CTID
EOF

APPARMOR=$(jq -r '.lxc.apparmorProfile // empty' <<<"$META")

if [[ "$APPARMOR" == "unconfined" ]]; then
  ssh root@"$NODE" \
    "echo 'lxc.apparmor.profile: unconfined' >> /etc/pve/lxc/${CTID}.conf"
fi

echo "LXC $NAME created (CTID $CTID)"

