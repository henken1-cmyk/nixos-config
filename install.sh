#!/usr/bin/env bash
# NixOS installer helper for lightspeed
# Run from the cloned repo directory on the NixOS live ISO AFTER:
#   1. Partitioning, encrypting, creating btrfs subvolumes
#   2. Mounting everything under /mnt
#   3. Running: nixos-generate-config --root /mnt
#
# Usage: bash install.sh /dev/nvme0n1p2

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

trap 'echo -e "${RED}[ERROR]${NC} Script failed at line $LINENO. Run: git checkout -- . to restore originals"' ERR

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
VARS_FILE="$REPO_DIR/hosts/lightspeed/variables.nix"
HW_CONFIG="$REPO_DIR/hosts/lightspeed/hardware-configuration.nix"
GENERATED="/mnt/etc/nixos/hardware-configuration.nix"
THEME_FILE="$REPO_DIR/themes/default.nix"
NIX_USER=$(grep 'username = ' "$VARS_FILE" | sed 's/.*= "//;s/".*//')
NIX_HOST=$(grep 'hostname = ' "$VARS_FILE" | sed 's/.*= "//;s/".*//')

# ── Arg: encrypted partition device ──────────────────────────────────

CRYPT_DEV="${1:-}"
if [[ -z "$CRYPT_DEV" ]]; then
  error "Usage: bash install.sh /dev/nvme0n1p2  (your LUKS partition)"
fi

if [[ ! -b "$CRYPT_DEV" ]]; then
  error "Device $CRYPT_DEV does not exist"
fi

# ── Check prerequisites ──────────────────────────────────────────────

[[ -f "$HW_CONFIG" ]]  || error "Cannot find $HW_CONFIG — run from the repo root"
[[ -d /mnt/boot ]]     || error "/mnt/boot not mounted — mount your partitions first"
[[ -f "$GENERATED" ]]  || error "$GENERATED not found — run: nixos-generate-config --root /mnt"

# ── Step 1: Merge hardware-configuration.nix ─────────────────────────

info "Merging hardware-configuration.nix..."

# Extract availableKernelModules from generated config
AVAIL_MODULES=$(grep 'availableKernelModules' "$GENERATED" | head -1 | sed 's/.*= //' | sed 's/;[[:space:]]*$//')
INITRD_MODULES=$(grep 'boot.initrd.kernelModules' "$GENERATED" | head -1 | sed 's/.*= //' | sed 's/;[[:space:]]*$//')
KERNEL_MODULES=$(grep 'boot.kernelModules' "$GENERATED" | head -1 | sed 's/.*= //' | sed 's/;[[:space:]]*$//')

if [[ -n "$AVAIL_MODULES" ]]; then
  sed -i "s|boot.initrd.availableKernelModules = .*|boot.initrd.availableKernelModules = ${AVAIL_MODULES};|" "$HW_CONFIG"
  info "  availableKernelModules: $AVAIL_MODULES"
fi

if [[ -n "$INITRD_MODULES" ]]; then
  sed -i "s|boot.initrd.kernelModules = .*|boot.initrd.kernelModules = ${INITRD_MODULES};|" "$HW_CONFIG"
  info "  initrd.kernelModules: $INITRD_MODULES"
fi

if [[ -n "$KERNEL_MODULES" ]]; then
  sed -i "s|boot.kernelModules = .*|boot.kernelModules = ${KERNEL_MODULES};|" "$HW_CONFIG"
  info "  kernelModules: $KERNEL_MODULES"
fi

# ── Step 2: Patch LUKS device UUID ───────────────────────────────────

info "Patching LUKS device UUID..."

CRYPT_UUID=$(blkid -s UUID -o value "$CRYPT_DEV")
if [[ -z "$CRYPT_UUID" ]]; then
  error "Could not read UUID from $CRYPT_DEV"
fi

sed -i "s|device = \"/dev/disk/by-[a-z]*/[^\"]*\".*|device = \"/dev/disk/by-uuid/$CRYPT_UUID\";|" "$HW_CONFIG"
if ! grep -q "by-uuid/$CRYPT_UUID" "$HW_CONFIG"; then
  error "Failed to patch LUKS UUID — check $HW_CONFIG manually"
fi
info "  LUKS UUID: $CRYPT_UUID"

# ── Step 3: Fetch and patch wallpaper SHA256 ─────────────────────────

info "Fetching wallpaper SHA256 hash..."

WALLPAPER_URL="https://github.com/kiperz/nixos-config/releases/download/1/wallpaper.jpeg"
WALLPAPER_HASH=$(nix-prefetch-url "$WALLPAPER_URL" 2>/dev/null) || true

if [[ -n "$WALLPAPER_HASH" ]]; then
  sed -i "s|sha256 = \"0000000000000000000000000000000000000000000000000000\".*|sha256 = \"$WALLPAPER_HASH\";|" "$THEME_FILE"
  info "  Wallpaper hash: $WALLPAPER_HASH"
else
  warn "Could not fetch wallpaper hash (no internet?). Fix manually:"
  warn "  nix-prefetch-url \"$WALLPAPER_URL\""
  warn "  Then update themes/default.nix"
fi

# ── Step 4: Prompt for CHANGEME values ───────────────────────────────

echo ""
info "Fill in your personal details:"
echo ""

read -rp "Email address: " USER_EMAIL
read -rp "Git username: " GIT_USER

if [[ -n "$USER_EMAIL" ]]; then
  sed -i "s|email = \"CHANGEME@example.com\".*|email = \"$USER_EMAIL\"; # Set your email|" "$VARS_FILE"
  info "  Email set to: $USER_EMAIL"
fi

if [[ -n "$GIT_USER" ]]; then
  sed -i "s|gitUsername = \"CHANGEME\".*|gitUsername = \"$GIT_USER\"; # Set your git username|" "$VARS_FILE"
  info "  Git username set to: $GIT_USER"
fi

# ── Step 5: Summary ──────────────────────────────────────────────────

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
info "Pre-install configuration complete!"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "Review changes:"
echo "  $HW_CONFIG"
echo "  $THEME_FILE"
echo "  $VARS_FILE"
echo ""
echo "Remaining CHANGEME (fix after first boot):"
echo "  - Monitor names: hyprctl monitors → variables.nix"
echo "  - Waybar hwmon: ls /sys/class/hwmon/*/temp*_input → waybar.nix"
echo ""
echo "Ready to install:"
echo "  nixos-install --flake $REPO_DIR#${NIX_HOST}"
echo ""

read -rp "Run nixos-install now? [y/N] " INSTALL_NOW
if [[ "$INSTALL_NOW" =~ ^[yY]$ ]]; then
  nixos-install --no-root-passwd --flake "$REPO_DIR#${NIX_HOST}"
  echo ""
  info "Setting password for $NIX_USER..."
  nixos-enter --root /mnt -c "passwd $NIX_USER"
  echo ""
  info "Done! Reboot when ready."
else
  info "Skipped. Run manually: nixos-install --no-root-passwd --flake $REPO_DIR#${NIX_HOST}"
fi
