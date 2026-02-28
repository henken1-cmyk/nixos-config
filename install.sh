#!/usr/bin/env bash
# NixOS installer helper — multi-host
# Run from the cloned repo directory on the NixOS live ISO AFTER:
#   1. Partitioning, encrypting, creating btrfs subvolumes
#   2. Mounting everything under /mnt
#   3. Running: nixos-generate-config --root /mnt
#
# Usage: bash install.sh <host> <luks-partition>
#   host:           lightspeed | adam
#   luks-partition: block device of the LUKS partition, e.g. /dev/nvme0n1p2
#
# Examples:
#   bash install.sh lightspeed /dev/nvme0n1p2
#   bash install.sh adam       /dev/nvme0n1p2

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
step()  { echo -e "\n${CYAN}══ $* ${NC}"; }

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
GENERATED="/mnt/etc/nixos/hardware-configuration.nix"
THEME_FILE="$REPO_DIR/themes/default.nix"

trap 'echo -e "${RED}[ERROR]${NC} Failed at line $LINENO. Run: git checkout -- . to restore originals"' ERR

# ── Args ──────────────────────────────────────────────────────────────

NIX_HOST="${1:-}"
CRYPT_DEV="${2:-}"

if [[ -z "$NIX_HOST" || -z "$CRYPT_DEV" ]]; then
  echo "Usage: bash install.sh <host> <luks-partition>"
  echo ""
  echo "Available hosts:"
  for d in "$REPO_DIR"/hosts/*/; do
    echo "  $(basename "$d")"
  done
  echo ""
  echo "Example: bash install.sh adam /dev/nvme0n1p2"
  exit 1
fi

HOST_DIR="$REPO_DIR/hosts/$NIX_HOST"
[[ -d "$HOST_DIR" ]] || error "Unknown host '$NIX_HOST' — no directory $HOST_DIR"

VARS_FILE="$HOST_DIR/variables.nix"
HW_CONFIG="$HOST_DIR/hardware-configuration.nix"
SYS_CONFIG="$HOST_DIR/configuration.nix"

[[ -f "$VARS_FILE" ]]  || error "Missing $VARS_FILE"
[[ -f "$HW_CONFIG" ]]  || error "Missing $HW_CONFIG"
[[ -b "$CRYPT_DEV" ]]  || error "Device $CRYPT_DEV does not exist"
[[ -d /mnt/boot ]]     || error "/mnt/boot not mounted — mount your partitions first"
[[ -f "$GENERATED" ]]  || error "$GENERATED not found — run: nixos-generate-config --root /mnt"

NIX_USER=$(grep 'username = ' "$VARS_FILE" | sed 's/.*= "//;s/".*//')

echo ""
echo -e "${GREEN}╔══════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  NixOS installer — host: $NIX_HOST$(printf '%*s' $((22 - ${#NIX_HOST})) '')║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════╝${NC}"

# ── Step 1: Merge kernel modules ──────────────────────────────────────

step "Merging kernel modules from nixos-generate-config..."

merge_module_line() {
  local key="$1"
  local val
  val=$(grep "$key" "$GENERATED" | head -1 | sed 's/.*= //' | sed 's/;[[:space:]]*$//')
  if [[ -n "$val" ]]; then
    sed -i "s|${key} = .*|${key} = ${val};|" "$HW_CONFIG"
    info "  $key = $val"
  fi
}

merge_module_line "boot.initrd.availableKernelModules"
merge_module_line "boot.initrd.kernelModules"
merge_module_line "boot.kernelModules"

# ── Step 2: Patch LUKS UUID ───────────────────────────────────────────

step "Patching LUKS UUID..."

CRYPT_UUID=$(blkid -s UUID -o value "$CRYPT_DEV")
[[ -n "$CRYPT_UUID" ]] || error "Could not read UUID from $CRYPT_DEV"

# Replace CHANGEME placeholder or existing by-uuid path in LUKS device line
sed -i "s|CHANGEME-LUKS-UUID|$CRYPT_UUID|g" "$HW_CONFIG"
# Also handle lightspeed-style (already has a real UUID — replace it)
sed -i "/luks\.devices/,/};/ s|device = \"/dev/disk/by-[a-z]*/[^\"]*\"|device = \"/dev/disk/by-uuid/$CRYPT_UUID\"|" "$HW_CONFIG"

grep -q "by-uuid/$CRYPT_UUID" "$HW_CONFIG" \
  || error "Failed to patch LUKS UUID — check $HW_CONFIG manually"
info "  LUKS UUID: $CRYPT_UUID"

# ── Step 3: Patch EFI UUID (if CHANGEME present) ──────────────────────

if grep -q "CHANGEME-EFI-UUID" "$HW_CONFIG"; then
  step "Patching EFI partition UUID..."

  # Derive EFI partition from LUKS partition (p2 → p1, or nvme0n1p2 → nvme0n1p1)
  if [[ "$CRYPT_DEV" =~ p[0-9]+$ ]]; then
    EFI_DEV="${CRYPT_DEV%p*}p1"
  else
    EFI_DEV="${CRYPT_DEV%[0-9]}1"
  fi

  if [[ -b "$EFI_DEV" ]]; then
    EFI_UUID=$(blkid -s UUID -o value "$EFI_DEV")
    [[ -n "$EFI_UUID" ]] || error "Could not read UUID from $EFI_DEV"
    sed -i "s|CHANGEME-EFI-UUID|$EFI_UUID|g" "$HW_CONFIG"
    info "  EFI UUID: $EFI_UUID (from $EFI_DEV)"
  else
    warn "Could not find EFI partition at $EFI_DEV — patch CHANGEME-EFI-UUID in $HW_CONFIG manually"
  fi
fi

# ── Step 4: Auto-detect GPU bus IDs (adam / PRIME offload hosts) ───────

if grep -q "CHANGEME.*intelBusId\|intelBusId.*CHANGEME\|intelBusId = \"PCI:0:2:0\"" "$SYS_CONFIG" 2>/dev/null; then
  step "Detecting GPU PCI bus IDs for PRIME offload..."

  pci_to_nix() {
    # Converts "00:02.0" → "PCI:0:2:0"
    echo "$1" | awk -F'[.:]' '{printf "PCI:%d:%d:%d", $1, $2, $3}'
  }

  INTEL_PCI=$(lspci | grep -Ei 'VGA.*Intel|Intel.*UHD|Intel.*HD Graphics' | awk '{print $1}' | head -1)
  NVIDIA_PCI=$(lspci | grep -Ei '3D.*NVIDIA|NVIDIA.*3D|VGA.*NVIDIA' | awk '{print $1}' | head -1)

  if [[ -n "$INTEL_PCI" && -n "$NVIDIA_PCI" ]]; then
    INTEL_BUS=$(pci_to_nix "$INTEL_PCI")
    NVIDIA_BUS=$(pci_to_nix "$NVIDIA_PCI")
    sed -i "s|intelBusId = \"[^\"]*\"|intelBusId = \"$INTEL_BUS\"|" "$SYS_CONFIG"
    sed -i "s|nvidiaBusId = \"[^\"]*\"|nvidiaBusId = \"$NVIDIA_BUS\"|" "$SYS_CONFIG"
    info "  Intel:  $INTEL_PCI → $INTEL_BUS"
    info "  NVIDIA: $NVIDIA_PCI → $NVIDIA_BUS"
  else
    warn "Could not auto-detect GPU bus IDs. Fix manually in $SYS_CONFIG:"
    warn "  lspci | grep -E 'VGA|3D'"
    lspci | grep -Ei 'VGA|3D' || true
  fi
fi

# ── Step 5: Fetch wallpaper SHA256 ────────────────────────────────────

step "Fetching wallpaper SHA256..."

WALLPAPER_URL="https://images.unsplash.com/photo-1462331940025-496dfbfc7564?w=3840"
WALLPAPER_HASH=$(nix-prefetch-url "$WALLPAPER_URL" 2>/dev/null) || true

if [[ -n "$WALLPAPER_HASH" ]]; then
  sed -i "s|sha256 = \"0000000000000000000000000000000000000000000000000000\".*|sha256 = \"$WALLPAPER_HASH\";|" "$THEME_FILE"
  info "  Hash: $WALLPAPER_HASH"
else
  warn "Could not fetch wallpaper hash (no internet?). Fix manually:"
  warn "  nix-prefetch-url \"$WALLPAPER_URL\""
  warn "  Then update themes/default.nix"
fi

# ── Step 6: Prompt for personal details ───────────────────────────────

step "Personal details..."
echo ""

CURRENT_EMAIL=$(grep 'email = ' "$VARS_FILE" | head -1 | sed 's/.*= "//;s/".*//')
CURRENT_GIT=$(grep 'gitUsername = ' "$VARS_FILE" | sed 's/.*= "//;s/".*//')

read -rp "Email address [$CURRENT_EMAIL]: " USER_EMAIL
read -rp "Git username  [$CURRENT_GIT]: "  GIT_USER

USER_EMAIL="${USER_EMAIL:-$CURRENT_EMAIL}"
GIT_USER="${GIT_USER:-$CURRENT_GIT}"

sed -i "s|email = \"[^\"]*\"; # CHANGEME.*|email = \"$USER_EMAIL\"; # Set your email|" "$VARS_FILE"
sed -i "s|gitUsername = \"[^\"]*\"; # CHANGEME.*|gitUsername = \"$GIT_USER\"; # Set your git username|" "$VARS_FILE"
# Fallback for any format
sed -i "s|email = \"[^\"]*\"|email = \"$USER_EMAIL\"|" "$VARS_FILE"
sed -i "s|gitUsername = \"[^\"]*\"|gitUsername = \"$GIT_USER\"|" "$VARS_FILE"

info "  Email:        $USER_EMAIL"
info "  Git username: $GIT_USER"

# ── Step 7: Summary ───────────────────────────────────────────────────

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
info "Pre-install configuration complete!"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "Review changes:"
echo "  $HW_CONFIG"
echo "  $THEME_FILE"
echo "  $VARS_FILE"
if grep -q "PRIME\|nvidia" "$SYS_CONFIG" 2>/dev/null; then
  echo "  $SYS_CONFIG  (GPU bus IDs)"
fi
echo ""
echo "Remaining CHANGEME (fix after first boot):"
echo "  - Monitor names:  hyprctl monitors → hosts/$NIX_HOST/variables.nix"
echo "  - Waybar sensor:  ls /sys/class/hwmon/*/temp*_input → home/system/waybar.nix"
if grep -q "resume_offset=CHANGEME" "$HW_CONFIG" 2>/dev/null; then
  echo "  - Hibernation:    btrfs inspect-internal map-swapfile -r /swap/swapfile"
  echo "                    → hosts/$NIX_HOST/hardware-configuration.nix (resume_offset)"
fi
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
  info "Skipped. Run manually:"
  info "  nixos-install --no-root-passwd --flake $REPO_DIR#${NIX_HOST}"
  info "  nixos-enter --root /mnt -c 'passwd $NIX_USER'"
fi
