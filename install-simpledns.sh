#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------
# SimpleDNS — Bootstrap Installer (SAFE, supports file execution)
# ---------------------------------------------------------

REPO_SSH="git@github.com:msbenjamin12/SimpleDNS.git"
CLONE_DIR_NAME="SimpleDNS"
INSTALL_REL_PATH="install/setup.sh"

banner() {
  echo "=========================================="
  echo "   SimpleDNS — Bootstrap Installer"
  echo "=========================================="
}

die() {
  echo "[ERROR] $*" >&2
  exit 1
}

# --- Guard: do not allow execution via pipe when elevation is needed ---
# If invoked as: curl ... | bash
# then $0 is typically "bash" and there's no file to re-exec with sudo.
if [[ "${EUID}" -ne 0 ]]; then
  # stdin is NOT a TTY => piped input
  if [[ ! -t 0 ]]; then
    banner
    echo
    echo "[ERROR] This installer cannot self-elevate when executed via a pipe (curl | bash)."
    echo
    echo "Use one of these SAFE methods instead:"
    echo
    echo "  curl -fsSL https://raw.githubusercontent.com/msbenjamin12/simpledns-bootstrap/main/install-simpledns.sh -o install-simpledns.sh"
    echo "  bash install-simpledns.sh"
    echo
    echo "Or:"
    echo
    echo "  curl -fsSL https://raw.githubusercontent.com/msbenjamin12/simpledns-bootstrap/main/install-simpledns.sh | sudo bash"
    echo
    exit 1
  fi

  echo "[INFO] Elevating to root..."
  exec sudo -E bash "$0" "$@"
fi

banner

# Identify the real (non-root) user to own SSH keys and perform git clone
REAL_USER="${SUDO_USER:-}"
if [[ -z "${REAL_USER}" || "${REAL_USER}" == "root" ]]; then
  # If someone runs as root directly, try to infer a sensible user
  # (best effort). They can also set REAL_USER manually before running.
  REAL_USER="$(logname 2>/dev/null || true)"
fi
[[ -n "${REAL_USER}" && "${REAL_USER}" != "root" ]] || die "Unable to determine non-root user. Run as: sudo -E bash install-simpledns.sh (from a normal user session)."

USER_HOME="$(eval echo "~${REAL_USER}")"
[[ -d "${USER_HOME}" ]] || die "User home not found for ${REAL_USER}: ${USER_HOME}"

# Ensure required tools exist
echo "[INFO] Installing prerequisites..."
apt-get update -y
apt-get install -y git openssh-client

# STEP 1 — Ensure SSH key (as real user)
SSH_DIR="${USER_HOME}/.ssh"
KEY_PATH="${SSH_DIR}/id_ed25519"
PUB_PATH="${KEY_PATH}.pub"

if [[ ! -f "${KEY_PATH}" ]]; then
  echo "[INFO] No SSH key found for ${REAL_USER} — generating one..."
  sudo -u "${REAL_USER}" mkdir -p "${SSH_DIR}"
  sudo -u "${REAL_USER}" chmod 700 "${SSH_DIR}"
  sudo -u "${REAL_USER}" ssh-keygen -t ed25519 -C "simpledns-bootstrap" -f "${KEY_PATH}" -N ""
fi

PUBKEY="$(cat "${PUB_PATH}")"

echo
echo "=========================================="
echo " ADD THIS SSH PUBLIC KEY TO GITHUB:"
echo " GitHub → Settings → SSH and GPG Keys → New SSH Key"
echo "=========================================="
echo "${PUBKEY}"
echo "------------------------------------------"
read -rp "Press ENTER once added to GitHub..."

echo
echo "[INFO] Testing SSH connection to GitHub..."
sudo -u "${REAL_USER}" ssh -o StrictHostKeyChecking=accept-new -T git@github.com || true

# STEP 2 — Clone repo (as real user)
echo
echo "[INFO] Cloning SimpleDNS into ${USER_HOME}/${CLONE_DIR_NAME} ..."
sudo -u "${REAL_USER}" rm -rf "${USER_HOME:?}/${CLONE_DIR_NAME}" 2>/dev/null || true
sudo -u "${REAL_USER}" git clone "${REPO_SSH}" "${USER_HOME}/${CLONE_DIR_NAME}"

# STEP 3 — Run hardened installer (as root)
INSTALL_PATH="${USER_HOME}/${CLONE_DIR_NAME}/${INSTALL_REL_PATH}"
[[ -f "${INSTALL_PATH}" ]] || die "Installer not found at ${INSTALL_PATH}"

echo
echo "=========================================="
echo " Running system installer "
echo "=========================================="

bash "${INSTALL_PATH}"

echo
echo "[INFO] Bootstrap complete."
echo "[INFO] Service status:"
systemctl status simpledns --no-pager || true
