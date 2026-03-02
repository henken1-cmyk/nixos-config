#!/usr/bin/env bash
# Boot Windows 11 from physical NVMe (nvme1n1) in a SPICE VM.
# Usage:
#   windows-vm.sh                                          # Normal boot
#   windows-vm.sh install /path/to/Win11.iso               # Install (ISO only)
#   windows-vm.sh install /path/to/Win11.iso virtio-win.iso # Install with VirtIO drivers

set -euo pipefail

DISK="/dev/nvme1n1"
OVMF_DIR="/etc/ovmf"
STATE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/windows-vm"
OVMF_VARS="$STATE_DIR/OVMF_VARS.ms.fd"
TPM_DIR="$STATE_DIR/tpm"
SPICE_PORT=5930
RAM="16G"
CPUS="8"

# ── Preflight checks ──────────────────────────────────────────
if [[ ! -b "$DISK" ]]; then
    echo "Error: $DISK is not a block device."
    exit 1
fi

if mountpoint -q /mnt/old-nvme 2>/dev/null; then
    echo "Error: /mnt/old-nvme is still mounted. Run: sudo umount /mnt/old-nvme"
    exit 1
fi

if mount | grep -q "$DISK"; then
    echo "Error: $DISK (or a partition) is currently mounted. Unmount first."
    exit 1
fi

if [[ ! -f "$OVMF_DIR/OVMF_CODE.ms.fd" ]]; then
    echo "Error: OVMF not found at $OVMF_DIR/. Rebuild NixOS first (nh os switch)."
    exit 1
fi

# ── State directory (UEFI vars + TPM state) ───────────────────
mkdir -p "$STATE_DIR" "$TPM_DIR"

if [[ ! -f "$OVMF_VARS" ]]; then
    cp "$OVMF_DIR/OVMF_VARS.ms.fd" "$OVMF_VARS"
    echo "Initialized UEFI variable store at $OVMF_VARS"
fi

# ── Start software TPM ────────────────────────────────────────
swtpm socket \
    --tpmstate dir="$TPM_DIR" \
    --ctrl type=unixio,path="$TPM_DIR/swtpm-sock" \
    --tpm2 \
    --log level=0 &
SWTPM_PID=$!
cleanup() {
    kill $SWTPM_PID 2>/dev/null; wait $SWTPM_PID 2>/dev/null
    [ -n "${QEMU_PID:-}" ] && sudo kill $QEMU_PID 2>/dev/null
}
trap cleanup EXIT
sleep 0.5

# ── QEMU arguments ────────────────────────────────────────────
QEMU_ARGS=(
    -enable-kvm
    -machine q35
    -m "$RAM"
    -cpu host
    -smp "$CPUS"

    # UEFI firmware (Secure Boot — needed for Win11)
    -drive if=pflash,format=raw,readonly=on,file="$OVMF_DIR/OVMF_CODE.ms.fd"
    -drive if=pflash,format=raw,file="$OVMF_VARS"

    # TPM 2.0
    -chardev socket,id=chrtpm,path="$TPM_DIR/swtpm-sock"
    -tpmdev emulator,id=tpm0,chardev=chrtpm
    -device tpm-tis,tpmdev=tpm0

    # Physical NVMe as AHCI disk (AHCI drivers work both in VM and bare metal)
    -drive file="$DISK",format=raw,if=none,id=disk0,cache=none,aio=native
    -device ahci,id=ahci
    -device ide-hd,drive=disk0,bus=ahci.0

    # Display: SPICE + QXL
    -spice port="$SPICE_PORT",disable-ticketing=on
    -device qxl-vga,vgamem_mb=128
    -device virtio-serial-pci
    -chardev spicevmc,id=vdagent,debug=0,name=vdagent
    -device virtserialport,chardev=vdagent,name=com.redhat.spice.0

    # Audio via SPICE
    -audiodev spice,id=snd0
    -device ich9-intel-hda
    -device hda-output,audiodev=snd0

    # Network (NAT — user-mode; e1000 has built-in Windows drivers)
    -device e1000,netdev=net0
    -netdev user,id=net0

    # USB tablet (seamless mouse, no grab)
    -usb
    -device usb-tablet

    -name "Windows 11"
)

# ── Install mode ──────────────────────────────────────────────
if [[ "${1:-}" == "install" ]]; then
    ISO="${2:?Usage: windows-vm.sh install /path/to/Win11.iso [/path/to/virtio-win.iso]}"
    if [[ ! -f "$ISO" ]]; then
        echo "Error: ISO not found: $ISO"
        exit 1
    fi
    QEMU_ARGS+=(
        -cdrom "$ISO"
        -boot d
    )
    if [[ -n "${3:-}" ]]; then
        QEMU_ARGS+=(-drive "file=$3,media=cdrom,index=1")
        echo "VirtIO drivers ISO: $3"
    fi
    echo "=== INSTALL MODE ==="
    echo "Windows ISO: $ISO"
    echo "Windows will install directly to physical disk $DISK"
    echo ""
fi

echo "SPICE: remote-viewer spice://localhost:$SPICE_PORT"
echo "Starting VM..."

# QEMU needs raw disk access → sudo
# Run in background so we can launch SPICE viewer after it starts
sudo qemu-system-x86_64 "${QEMU_ARGS[@]}" &
QEMU_PID=$!

# Wait for SPICE port to become available, then launch viewer
for i in $(seq 1 30); do
    if ss -tlnp 2>/dev/null | grep -q ":$SPICE_PORT "; then
        remote-viewer "spice://localhost:$SPICE_PORT" 2>/dev/null &
        break
    fi
    sleep 0.5
done

wait $QEMU_PID
