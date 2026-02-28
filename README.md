# NixOS Bonkers Setup — `lightspeed`

> NixOS + Hyprland + Solarized · dual 4K · NVIDIA RTX 3090 Ti · btrfs on LUKS

## Quick Start

### 1. Install NixOS (minimal ISO)

```bash
# Partition (Drive 1: NixOS)
gdisk /dev/nvme0n1
# p1: 512M EFI (ef00), label: BOOT
# p2: remaining, Linux filesystem (8300), label: CRYPTBTRFS

# Encrypt
cryptsetup luksFormat --type luks2 /dev/disk/by-partlabel/CRYPTBTRFS
cryptsetup open /dev/disk/by-partlabel/CRYPTBTRFS cryptbtrfs

# Create btrfs filesystem
mkfs.fat -F32 -n BOOT /dev/nvme0n1p1
mkfs.btrfs -L nixos /dev/mapper/cryptbtrfs

# Create subvolumes
mount /dev/mapper/cryptbtrfs /mnt
btrfs subvolume create /mnt/@root
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@devel
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@swap
umount /mnt

# Mount subvolumes
mount -o subvol=@root,compress=zstd:1,noatime,space_cache=v2,ssd,discard=async /dev/mapper/cryptbtrfs /mnt
mkdir -p /mnt/{boot,home,nix,devel,var/log,.snapshots,swap}

mount /dev/nvme0n1p1 /mnt/boot
mount -o subvol=@home,compress=zstd:1,noatime,space_cache=v2,ssd,discard=async /dev/mapper/cryptbtrfs /mnt/home
mount -o subvol=@nix,noatime,ssd,discard=async,nodatacow /dev/mapper/cryptbtrfs /mnt/nix
mount -o subvol=@devel,compress=zstd:1,noatime,space_cache=v2,ssd,discard=async /dev/mapper/cryptbtrfs /mnt/devel
mount -o subvol=@log,compress=zstd:1,noatime,space_cache=v2,ssd,discard=async /dev/mapper/cryptbtrfs /mnt/var/log
mount -o subvol=@snapshots,compress=zstd:1,noatime,space_cache=v2,ssd,discard=async /dev/mapper/cryptbtrfs /mnt/.snapshots
mount -o subvol=@swap,noatime,ssd,discard=async,nodatacow /dev/mapper/cryptbtrfs /mnt/swap

# Swap file (match your RAM for hibernation)
btrfs filesystem mkswapfile --size 64g /mnt/swap/swapfile
swapon /mnt/swap/swapfile

# Generate hardware config
nixos-generate-config --root /mnt
```

### 2. Clone and Configure

```bash
# Install git in the live ISO environment
nix-shell -p git

# Clone this repo
git clone <your-repo-url> /mnt/home/kiper/.config/nixos
cd /mnt/home/kiper/.config/nixos
```

**Option A — Automated (recommended):**
```bash
# The install script handles everything: merges hardware config, patches LUKS UUID,
# fetches wallpaper hash, prompts for email/username, and runs nixos-install.
bash install.sh /dev/nvme0n1p2   # ← your LUKS partition
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
nixos-install --flake /mnt/home/kiper/.config/nixos#lightspeed

# Set user password (nixos-install prompts for root password automatically)
nixos-enter --root /mnt -c 'passwd kiper'

reboot
```

### 4. Post-Install

```bash
# Fix monitor names
hyprctl monitors
# Update monitorLeft / monitorRight in variables.nix

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

# Verify btrfs setup
sudo btrfs subvolume list /           # all 7 subvolumes
findmnt -t btrfs                      # correct mount options
swapon --show                         # swap active
systemctl status btrbk-default.timer  # snapshots scheduled
systemctl status btrfs-scrub@-.timer  # scrub scheduled
ls -la /devel                         # 2775 root:devel
nvidia-smi                            # GPU driver loaded

# Rebuild
nh os switch
```

## CHANGEME Markers

Search for `CHANGEME` across the config — these are values you must update:

| File | What | When |
|------|------|------|
| `themes/default.nix` | Wallpaper sha256 hash | **Before install** (build blocker) |
| `hosts/lightspeed/variables.nix` | email, gitUsername | **Before install** |
| `hosts/lightspeed/hardware-configuration.nix` | Merge kernel modules + LUKS UUID | **Before install** (use `install.sh`) |
| `hosts/lightspeed/variables.nix` | monitorLeft, monitorRight | After first boot |
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
├── flake.nix                    # Entry point
├── hosts/lightspeed/
│   ├── configuration.nix        # System config
│   ├── hardware-configuration.nix # Generated
│   ├── home.nix                 # Home Manager entry
│   └── variables.nix            # Per-machine values
├── nixos/                       # System modules
│   ├── audio.nix                # PipeWire
│   ├── bluetooth.nix            # Bluez + Blueman
│   ├── boot.nix                 # LUKS + btrfs + systemd-boot
│   ├── btrfs.nix                # btrfs scrub + btrbk snapshots
│   ├── docker.nix               # Docker daemon
│   ├── flatpak.nix              # Flatpak + Flathub
│   ├── gpu.nix                  # NVIDIA 3090 Ti
│   ├── greetd.nix               # GUI login
│   ├── locale.nix               # Warsaw, PL layout
│   ├── networking.nix           # NetworkManager
│   ├── nix.nix                  # Flakes, GC, caches
│   ├── printing.nix             # CUPS + PDF printer
│   ├── sysctl.nix               # inotify limits, fast shutdown
│   └── users.nix                # kiper account
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
│   │   ├── hyprland.nix         # WM + keybinds + rules
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
3. If open driver is the issue — select previous generation from systemd-boot menu, then:
   ```bash
   # In gpu.nix: change open = true → open = false
   sudo nixos-rebuild switch
   ```
4. Nuclear option: add `nomodeset` to kernel params (press `e` on boot entry in systemd-boot)

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
cd /home/kiper/.config/nixos
nano <broken-file>
nixos-rebuild boot
exit
reboot
```

## Future Additions

- [ ] VFIO GPU passthrough module (when secondary GPU acquired)
- [ ] sops-nix encrypted secrets
- [ ] Gaming runtime (Steam + Proton, gamemode, mangohud)
- [ ] GPG signing for git commits