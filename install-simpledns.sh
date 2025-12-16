#!/bin/bash

echo "=========================================="
echo "     SimpleDNS — Automatic DEV Installer"
echo "=========================================="

# STEP 1 — Ensure SSH Key
if [[ ! -f ~/.ssh/id_ed25519 ]]; then
  echo "[INFO] No SSH key found — generating one..."
  ssh-keygen -t ed25519 -C "simpledns-auto" -f ~/.ssh/id_ed25519 -N ""
fi

PUBKEY=$(cat ~/.ssh/id_ed25519.pub)

echo
echo "=========================================="
echo " ADD THIS SSH PUBLIC KEY TO GITHUB:"
echo " GitHub -> Settings -> SSH and GPG Keys -> New SSH Key"
echo "=========================================="
echo "$PUBKEY"
echo "------------------------------------------"
read -p "Press ENTER once added to GitHub..."

echo "[INFO] Testing SSH connection..."
ssh -T git@github.com || true

# STEP 2 — Clone repo
rm -rf SimpleDNS 2>/dev/null || true

echo "[INFO] Cloning SimpleDNS..."
git clone git@github.com:msbenjamin12/SimpleDNS.git

# STEP 3 — Run installer WITH root permissions
cd SimpleDNS/install
sudo bash setup.sh
