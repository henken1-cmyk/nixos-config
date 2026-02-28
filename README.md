# NixOS Bonkers Setup

> NixOS + Hyprland + Solarized · multi-host flake

| Host | Machine | CPU | GPU | Display |
|------|---------|-----|-----|---------|
| `lightspeed` | Desktop | AMD | NVIDIA RTX 3090 Ti | Dual 4K (60+240Hz) |
| `adam` | Lenovo ThinkPad T480s | Intel i7-8550U | Intel UHD 620 + NVIDIA MX150 | 1366x768 |

## Quick Start

### 1. Partition & Encrypt (from minimal ISO)

Both hosts use LUKS + btrfs. Choose your host below.

<details>
<summary><b>lightspeed</b> (desktop) — 7 subvolumes, 64 GB swap, @devel</summary>

```bash
# Partition
gdisk /dev/nvme0n1
# p1: 512M EFI (ef00), label: BOOT
# p2: remaining, Linux filesystem (8300), label: CRYPTBTRFS

# Encrypt + format
cryptsetup luksFormat --type luks2 /dev/disk/by-partlabel/CRYPTBTRFS
cryptsetup open /dev/disk/by-partlabel/CRYPTBTRFS cryptbtrfs
mkfs.fat -F32 -n BOOT /dev/nvme0n1p1
mkfs.btrfs -L nixos /dev/mapper/cryptbtrfs

# Create subvolumes (7: root, home, nix, devel, log, snapshots, swap)
mount /dev/mapper/cryptbtrfs /mnt
btrfs subvolume create /mnt/@root
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@devel
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@swap
umount /mnt

# Mount
mount -o subvol=@root,compress=zstd:1,noatime,space_cache=v2,ssd,discard=async /dev/mapper/cryptbtrfs /mnt
mkdir -p /mnt/{boot,home,nix,devel,var/log,.snapshots,swap}

mount /dev/nvme0n1p1 /mnt/boot
mount -o subvol=@home,compress=zstd:1,noatime,space_cache=v2,ssd,discard=async /dev/mapper/cryptbtrfs /mnt/home
mount -o subvol=@nix,noatime,ssd,discard=async,nodatacow /dev/mapper/cryptbtrfs /mnt/nix
mount -o subvol=@devel,compress=zstd:1,noatime,space_cache=v2,ssd,discard=async /dev/mapper/cryptbtrfs /mnt/devel
mount -o subvol=@log,compress=zstd:1,noatime,space_cache=v2,ssd,discard=async /dev/mapper/cryptbtrfs /mnt/var/log
mount -o subvol=@snapshots,compress=zstd:1,noatime,space_cache=v2,ssd,discard=async /dev/mapper/cryptbtrfs /mnt/.snapshots
mount -o subvol=@swap,noatime,ssd,discard=async,nodatacow /dev/mapper/cryptbtrfs /mnt/swap

# 64 GB swap (match RAM for hibernation)
btrfs filesystem mkswapfile --size 64g /mnt/swap/swapfile
swapon /mnt/swap/swapfile

nixos-generate-config --root /mnt
```
</details>

<details>
<summary><b>adam</b> (ThinkPad T480s) — 6 subvolumes, 16 GB swap + hibernation, no @devel</summary>

```bash
# Partition (256 GB NVMe)
gdisk /dev/nvme0n1
# p1: 512M EFI (ef00), label: BOOT
# p2: remaining, Linux filesystem (8300), label: CRYPTBTRFS

# Encrypt + format
cryptsetup luksFormat --type luks2 /dev/disk/by-partlabel/CRYPTBTRFS
cryptsetup open /dev/disk/by-partlabel/CRYPTBTRFS cryptbtrfs
mkfs.fat -F32 -n BOOT /dev/nvme0n1p1
mkfs.btrfs -L nixos /dev/mapper/cryptbtrfs

# Create subvolumes (6: root, home, nix, log, snapshots, swap — no @devel)
mount /dev/mapper/cryptbtrfs /mnt
btrfs subvolume create /mnt/@root
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@swap
umount /mnt

# Mount
mount -o subvol=@root,compress=zstd:1,noatime,space_cache=v2,ssd,discard=async /dev/mapper/cryptbtrfs /mnt
mkdir -p /mnt/{boot,home,nix,var/log,.snapshots,swap}

mount /dev/nvme0n1p1 /mnt/boot
mount -o subvol=@home,compress=zstd:1,noatime,space_cache=v2,ssd,discard=async /dev/mapper/cryptbtrfs /mnt/home
mount -o subvol=@nix,noatime,ssd,discard=async,nodatacow /dev/mapper/cryptbtrfs /mnt/nix
mount -o subvol=@log,compress=zstd:1,noatime,space_cache=v2,ssd,discard=async /dev/mapper/cryptbtrfs /mnt/var/log
mount -o subvol=@snapshots,compress=zstd:1,noatime,space_cache=v2,ssd,discard=async /dev/mapper/cryptbtrfs /mnt/.snapshots
mount -o subvol=@swap,noatime,ssd,discard=async,nodatacow /dev/mapper/cryptbtrfs /mnt/swap

# 16 GB swap (matches RAM for hibernation)
btrfs filesystem mkswapfile --size 16g /mnt/swap/swapfile
swapon /mnt/swap/swapfile

nixos-generate-config --root /mnt
```
</details>

### 2. Clone and Configure

```bash
# Install git in the live ISO environment
nix-shell -p git

# Clone this repo (replace <user> with your username: kiper for lightspeed, adam for adam)
git clone <your-repo-url> /mnt/home/<user>/.config/nixos
cd /mnt/home/<user>/.config/nixos
```

**Option A — Automated (recommended):**
```bash
# install.sh handles: kernel modules merge, LUKS+EFI UUID patching,
# GPU bus ID detection (PRIME hosts), wallpaper hash, email/username prompt.
bash install.sh lightspeed /dev/nvme0n1p2   # ← host name + LUKS partition
bash install.sh adam       /dev/nvme0n1p2
```

**Option B — Manual:**
<details>
<summary>Click to expand manual steps</summary>

```bash
# ── Fix wallpaper hash (BUILD BLOCKER) ──
nix-prefetch-url "https://images.unsplash.com/photo-1462331940025-496dfbfc7564?w=3840&q=95"
# Copy the output hash and replace the placeholder in themes/default.nix:
nano themes/default.nix   # replace sha256 = "0000..." with the real hash

# ── Merge hardware config ──
# DO NOT just copy the generated file — it would overwrite btrfs subvolume mounts.
# Instead, open both files side by side and copy ONLY these from the generated one:
#   - boot.initrd.availableKernelModules (your actual hardware's modules)
#   - boot.initrd.kernelModules (if any)
#   - boot.kernelModules (if different)
# Keep everything else from the repo version (btrfs mounts, LUKS, swap).
diff /mnt/etc/nixos/hardware-configuration.nix hosts/lightspeed/hardware-configuration.nix
nano hosts/lightspeed/hardware-configuration.nix

# ── Update LUKS device path ──
blkid /dev/nvme0n1p2
# Update the device path in hardware-configuration.nix:
#   device = "/dev/disk/by-uuid/YOUR-UUID-HERE";

# ── Fill CHANGEME values ──
nano hosts/lightspeed/variables.nix   # email, gitUsername
```
</details>

### 3. Install (if you used manual steps above)

```bash
# For lightspeed (desktop):
nixos-install --flake /mnt/home/kiper/.config/nixos#lightspeed
nixos-enter --root /mnt -c 'passwd kiper'

# For adam (ThinkPad T480s):
nixos-install --flake /mnt/home/adam/.config/nixos#adam
nixos-enter --root /mnt -c 'passwd adam'

reboot
```

### 4. Post-Install

```bash
# Fix monitor names
hyprctl monitors
# Update monitors list in hosts/<hostname>/variables.nix

# Fix Waybar temperature sensor
ls /sys/class/hwmon/*/temp*_input
# Update hwmon-path-abs in home/system/waybar.nix

# Download wallpaper for swww
mkdir -p ~/wallpapers
# Place your wallpaper at ~/wallpapers/space-solarized.png

# Add Flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Install Flatpak apps
flatpak install flathub md.obsidian.Obsidian
flatpak install flathub dev.vencord.Vesktop

# Verify setup
nvidia-smi                            # GPU driver loaded
nh os switch                          # rebuild

# (lightspeed only) Verify btrfs
sudo btrfs subvolume list /           # all 7 subvolumes
findmnt -t btrfs                      # correct mount options
swapon --show                         # swap active
systemctl status btrbk-default.timer  # snapshots scheduled

# (adam only) Verify laptop features
nvidia-offload glxinfo | head         # PRIME offload works
systemctl status tlp.service          # TLP active
systemctl status thermald.service     # thermal management
cat /sys/class/power_supply/BAT0/charge_control_start_threshold  # 75
cat /sys/class/power_supply/BAT0/charge_control_end_threshold    # 80

# (adam only) Enable hibernation — calculate swap offset
sudo btrfs inspect-internal map-swapfile -r /swap/swapfile
# Copy the offset number and set it in hosts/adam/hardware-configuration.nix:
#   boot.kernelParams = [ "resume_offset=<number>" ];
# Then rebuild: nh os switch
```

## CHANGEME Markers

Search for `CHANGEME` across the config — these are values you must update:

| File | What | When |
|------|------|------|
| `themes/default.nix` | Wallpaper sha256 hash | **Before install** (build blocker) |
| `hosts/*/variables.nix` | email, gitUsername | **Before install** |
| `hosts/*/hardware-configuration.nix` | Kernel modules + disk UUIDs | **Before install** |
| `hosts/*/variables.nix` | monitors list | After first boot (`hyprctl monitors`) |
| `hosts/adam/configuration.nix` | GPU bus IDs (intelBusId, nvidiaBusId) | **Before install** (`lspci \| grep -E 'VGA\|3D'`) |
| `hosts/adam/hardware-configuration.nix` | resume_offset for hibernation | After first boot (`btrfs inspect-internal map-swapfile`) |
| `home/system/waybar.nix` | temperature hwmon path | After first boot |

## Key Bindings (Cheat Sheet)

| Bind | Action |
|------|--------|
| `Super+Return` | Terminal (Ghostty + Zellij) |
| `Super+D` | App launcher (Fuzzel) |
| `Super+Q` | Close window |
| `Super+Shift+Q` | Force kill (click to select) |
| `Super+E` | Thunar |
| `Super+Shift+E` | Yazi (terminal) |
| `Super+B` | Firefox |
| `Super+V` | Clipboard history |
| `Super+BackSpace` | Power menu |
| `Super+L` | Lock screen |
| `Super+Space` | Toggle float |
| `Super+F` | Fullscreen |
| `Super+Shift+F` | Fake fullscreen (monocle) |
| `Super+R` | Resize mode (arrows, Esc to exit) |
| `Super+Arrows` | Focus window |
| `Super+Ctrl+Arrows` | Swap windows |
| `Super+Shift+1-9` | Move window to workspace |
| `Super+Shift+Arrows` | Move to adjacent workspace |
| `Super+Tab` | Previous workspace |
| `Alt+Tab` | Cycle windows |
| `Super+.` | Emoji picker |
| `Print` | Screenshot (fullscreen → satty) |
| `Super+Shift+S` | Screenshot (region → satty) |
| `Super+Shift+R` | Toggle screen recording |
| `XF86AudioPlay` | Play/Pause media |
| `XF86AudioNext/Prev` | Next/Previous track |

## Structure

```
├── install.sh                   # Automated installer helper
├── flake.nix                    # Entry point (both hosts)
├── hosts/
│   ├── lightspeed/              # Desktop (AMD + RTX 3090 Ti, dual 4K)
│   │   ├── configuration.nix    # System config + desktop GPU
│   │   ├── hardware-configuration.nix # btrfs-on-LUKS, 7 subvols, NVMe
│   │   ├── home.nix             # Home Manager entry
│   │   └── variables.nix        # Per-machine values
│   └── adam/                    # Laptop (ThinkPad T480s, i7-8550U)
│       ├── configuration.nix    # System config + PRIME offload + TLP
│       ├── hardware-configuration.nix # btrfs-on-LUKS, 6 subvols, hibernation
│       ├── home.nix             # Home Manager entry
│       └── variables.nix        # Per-machine values
├── nixos/                       # Shared system modules
│   ├── audio.nix                # PipeWire
│   ├── bluetooth.nix            # Bluez + Blueman
│   ├── boot.nix                 # systemd-boot + latest kernel
│   ├── btrfs.nix                # btrfs scrub + btrbk snapshots
│   ├── docker.nix               # Docker daemon
│   ├── flatpak.nix              # Flatpak + Flathub
│   ├── gpu.nix                  # NVIDIA desktop (lightspeed only)
│   ├── greetd.nix               # GUI login
│   ├── locale.nix               # Warsaw, PL layout
│   ├── networking.nix           # NetworkManager
│   ├── nix.nix                  # Flakes, GC, caches
│   ├── printing.nix             # CUPS + PDF printer
│   ├── sysctl.nix               # inotify limits, fast shutdown
│   └── users.nix                # User account (from vars)
├── home/
│   ├── packages.nix             # All user packages
│   ├── programs/                # App configs
│   │   ├── browser.nix          # Firefox + extensions
│   │   ├── editor.nix           # VSCode
│   │   ├── fish.nix             # Fish + Starship
│   │   ├── ghostty.nix          # Terminal
│   │   ├── git.nix              # Git + delta
│   │   ├── neovim.nix           # NixVim full IDE
│   │   ├── yazi.nix             # TUI file manager
│   │   └── zellij.nix           # Multiplexer
│   ├── system/                  # Desktop environment
│   │   ├── hyprland.nix         # WM + keybinds + rules + touchpad
│   │   ├── waybar.nix           # Status bar
│   │   ├── fuzzel.nix           # Launcher
│   │   ├── mako.nix             # Notifications
│   │   ├── hypridle.nix         # Idle management
│   │   ├── hyprlock.nix         # Lock screen
│   │   └── swww.nix             # Wallpaper
│   └── scripts/                 # Helper scripts
│       ├── power-menu.sh
│       ├── theme-toggle.sh
│       └── screen-record.sh
└── themes/
    └── default.nix              # Stylix Solarized config
```

### Variables pattern

Each host has a `variables.nix` with machine-specific values. Shared modules receive `vars` via `specialArgs` (system) and `extraSpecialArgs` (Home Manager), set in `flake.nix`. This allows the same modules to work across all hosts without hardcoded paths.

## Troubleshooting

### Build fails on wallpaper hash
**Symptom:** `hash mismatch` during `nixos-install`
```bash
nix-prefetch-url "https://images.unsplash.com/photo-1462331940025-496dfbfc7564?w=3840&q=95"
# Replace the hash in themes/default.nix, re-run nixos-install
```

### LUKS device not found on boot
**Symptom:** Drops to emergency shell, "device not found"
```bash
# Boot live ISO, find the correct UUID:
blkid /dev/nvme0n1p2
# Mount and fix:
cryptsetup open /dev/nvme0n1p2 cryptbtrfs
mount -o subvol=@root,compress=zstd:1,noatime /dev/mapper/cryptbtrfs /mnt
# Update hardware-configuration.nix with the correct by-uuid path
nixos-enter --root /mnt -c 'nixos-rebuild boot'
```

### Swap file won't activate
**Symptom:** `swapon: Invalid argument`
```bash
# Boot live ISO, recreate the swap file properly:
cryptsetup open /dev/nvme0n1p2 cryptbtrfs
mount -o subvol=@swap,noatime,ssd,discard=async,nodatacow /dev/mapper/cryptbtrfs /mnt
rm /mnt/swapfile
btrfs filesystem mkswapfile --size 64g /mnt/swapfile
```

### Black screen after boot (NVIDIA)
**Symptom:** LUKS prompt works, but no display after login
1. Try switching TTY: `Ctrl+Alt+F2`
2. Check logs: `journalctl -b -u greetd`
3. **lightspeed**: If open driver is the issue — select previous generation from systemd-boot menu, then change `open = true` to `open = false` in `nixos/gpu.nix`
4. **adam**: If PRIME offload causes issues, verify bus IDs: `lspci | grep -E 'VGA|3D'` and update `intelBusId`/`nvidiaBusId` in `hosts/adam/configuration.nix`
5. Nuclear option: add `nomodeset` to kernel params (press `e` on boot entry in systemd-boot)

### greetd won't start (no login screen)
**Symptom:** Boots to TTY instead of graphical login

greetd depends on `config.stylix.image` which depends on the wallpaper hash. If the hash is wrong, the entire stylix config fails to evaluate.
```bash
journalctl -b -u greetd
# Fix the wallpaper hash in themes/default.nix and rebuild
```

### btrbk snapshots not working
```bash
# Dry-run to see what's wrong:
sudo btrbk -n run
# Check timer:
systemctl status btrbk-default.timer
```

### Recovery from live ISO
General approach for any boot failure:
```bash
cryptsetup open /dev/nvme0n1p2 cryptbtrfs
mount -o subvol=@root,compress=zstd:1,noatime /dev/mapper/cryptbtrfs /mnt
mkdir -p /mnt/{home,nix,var/log,boot}
mount -o subvol=@home,compress=zstd:1,noatime /dev/mapper/cryptbtrfs /mnt/home
mount -o subvol=@nix,noatime,nodatacow /dev/mapper/cryptbtrfs /mnt/nix
mount -o subvol=@log,compress=zstd:1,noatime /dev/mapper/cryptbtrfs /mnt/var/log
mount /dev/nvme0n1p1 /mnt/boot

# Chroot and fix:
nixos-enter --root /mnt
cd /home/<user>/.config/nixos   # kiper for lightspeed, adam for adam
nano <broken-file>
nixos-rebuild boot
exit
reboot
```

## Host-specific notes

### `lightspeed` (Desktop)
- NVIDIA RTX 3090 Ti with open kernel modules (`nixos/gpu.nix`)
- Dual 4K monitors: HP 727pk 27" 60Hz + Samsung Odyssey G80SD 32" 240Hz
- btrfs on LUKS — 7 subvolumes (@root, @home, @nix, @devel, @log, @snapshots, @swap)
- btrbk snapshots (hourly, 48h/14d/4w/3m retention) for @root, @home, @devel
- 64 GB swap file

### `adam` (ThinkPad T480s)
- Intel UHD 620 (primary) + NVIDIA MX150 in **PRIME offload** mode
  - Run GPU-intensive apps with: `nvidia-offload <command>`
- btrfs on LUKS — 6 subvolumes (@root, @home, @nix, @log, @snapshots, @swap — no @devel)
- 16 GB swap file with **hibernation** (lid close on battery = hibernate)
- TLP power management with ThinkPad battery thresholds (75-80%)
- thermald for Intel thermal management
- Lid switch: hibernate on battery, lock on AC
- `hardware-configuration.nix` is a **template** — merge UUIDs from `nixos-generate-config`

## Future Additions

- [ ] VFIO GPU passthrough module (when secondary GPU acquired)
- [ ] sops-nix encrypted secrets
- [ ] Gaming runtime (Steam + Proton, gamemode, mangohud)
- [ ] GPG signing for git commits