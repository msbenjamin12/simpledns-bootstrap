#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------
# SimpleDNS — Bootstrap Installer (PIPE-SAFE)
# ---------------------------------------------------------

# Re-exec as root if needed (PIPE SAFE)
if [[ $EUID -ne 0 ]]; then
  echo "[INFO] Elevating to root..."
  exec sudo -E bash "$0" "$@"
fi

echo "=========================================="
echo "   SimpleDNS — Bootstrap Installer"
echo "=========================================="

# Preserve original user home (important!)
REAL_USER="${SUDO_USER:-root}"
USER_HOME="$(eval echo "~$REAL_USER")"

# STEP 1 — Ensure SSH key (as real user)
if [[ ! -f "$USER_HOME/.ssh/id_ed25519" ]]; then
  echo "[INFO] No SSH key found — generating one..."
  sudo -u "$REAL_USER" ssh-keygen -t ed25519 -C "simpledns-bootstrap" -f "$USER_HOME/.ssh/id_ed25519" -N ""
fi

PUBKEY=$(cat "$USER_HOME/.ssh/id_ed25519.pub")

echo
echo "=========================================="
echo " ADD THIS SSH PUBLIC KEY TO GITHUB:"
echo " GitHub → Settings → SSH and GPG Keys → New SSH Key"
echo "=========================================="
echo "$PUBKEY"
echo "------------------------------------------"
read -rp "Press ENTER once added to GitHub..."

echo "[INFO] Testing SSH connection..."
sudo -u "$REAL_USER" ssh -T git@github.com || true

# STEP 2 — Clone repo (as real user)
cd "$USER_HOME"
rm -rf SimpleDNS 2>/dev/null || true

echo "[INFO] Cloning SimpleDNS..."
sudo -u "$REAL_USER" git clone git@github.com:msbenjamin12/SimpleDNS.git

# STEP 3 — Run hardened installer (already root)
echo
echo "=========================================="
echo " Running system installer "
echo "=========================================="

cd SimpleDNS/install
bash setup.sh
