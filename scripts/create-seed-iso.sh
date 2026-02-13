#!/bin/bash
# Generate a cloud-init seed ISO for a specific host
# Usage: ./create-seed-iso.sh <hostname> [output-dir]
#
# Examples:
#   ./create-seed-iso.sh vpac-host1
#   ./create-seed-iso.sh vpac-host2 /home/admin/isos/
#   ./create-seed-iso.sh vpac-host3 . admin r3dH4T1

set -euo pipefail

HOSTNAME="${1:?Usage: $0 <hostname> [output-dir] [admin-user] [admin-password]}"
OUTPUT_DIR="${2:-.}"
ADMIN_USER="${3:-admin}"
ADMIN_PASSWORD="${4:-}"
SSH_PUBKEY_FILE="${SSH_PUBKEY_FILE:-$HOME/.ssh/id_ed25519.pub}"

if [[ ! -f "$SSH_PUBKEY_FILE" ]]; then
    echo "ERROR: SSH public key not found at $SSH_PUBKEY_FILE"
    echo "Set SSH_PUBKEY_FILE to point to your public key"
    exit 1
fi

SSH_PUBKEY=$(cat "$SSH_PUBKEY_FILE")

if [[ -z "$ADMIN_PASSWORD" ]]; then
    read -s -p "Enter password for $ADMIN_USER: " ADMIN_PASSWORD
    echo
fi

PASSWORD_HASH=$(python3 -c "import crypt; print(crypt.crypt('$ADMIN_PASSWORD', crypt.mksalt(crypt.METHOD_SHA512)))")
INSTANCE_ID=$(uuidgen)

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

# meta-data
cat > "$TMPDIR/meta-data" << EOF
---
instance-id: "$INSTANCE_ID"
local-hostname: "$HOSTNAME"
...
EOF

# user-data
cat > "$TMPDIR/user-data" << EOF
#cloud-config
users:
- name: $ADMIN_USER
  ssh_authorized_keys:
  - $SSH_PUBKEY
  groups: ["wheel"]
  passwd: $PASSWORD_HASH
  shell: /bin/bash
  sudo: ['ALL=(ALL) NOPASSWD:ALL']

ssh_pwauth: true
chpasswd:
  expire: false

runcmd:
- echo "Cloud-Init completed successfully" > /var/log/cloud-init-success.log
- echo "Welcome to vPAC on RHEL" > /etc/motd
EOF

# network-config
cat > "$TMPDIR/network-config" << EOF
---
version: 2
ethernets:
  id0:
    match:
      name: "e*"
    dhcp4: true
EOF

ISO_NAME="${HOSTNAME}-seed.iso"
genisoimage -output "$OUTPUT_DIR/$ISO_NAME" -volid cidata -joliet -rock "$TMPDIR/" 2>/dev/null

echo "Created: $OUTPUT_DIR/$ISO_NAME"
echo "  Hostname:  $HOSTNAME"
echo "  User:      $ADMIN_USER"
echo "  Instance:  $INSTANCE_ID"
