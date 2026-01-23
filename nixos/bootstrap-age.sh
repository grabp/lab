#!/usr/bin/env bash
set -euo pipefail

HOST="$1"
KEY_SRC="$HOME/.config/sops/age/keys.txt"
KEY_DST="/var/lib/sops-nix/key.txt"

ssh "$HOST" "sudo install -d -m 0700 /var/lib/sops-nix"
scp "$KEY_SRC" "$HOST:/tmp/age.key"
ssh "$HOST" "sudo install -m 0400 /tmp/age.key $KEY_DST && rm /tmp/age.key"
