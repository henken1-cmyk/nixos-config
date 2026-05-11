# Gaming Support Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add gaming capability to lightspeed — Wine/Lutris for FitGirl repacks, dedicated /games btrfs subvolume with nodatacow, performance tooling.

**Architecture:** New `nixos/gaming.nix` system module for Steam/GameMode/Gamescope/esync. Gaming user packages in lightspeed's `home.nix`. New `@games` btrfs subvolume mounted at `/games` with nodatacow. Lightspeed-only — adam laptop unchanged.

**Tech Stack:** Wine (staging, Wow64), Lutris, DXVK/VKD3D-Proton (via Lutris), GameMode, Gamescope, MangoHud, btrfs nodatacow subvolume.

---

### Task 1: Create @games btrfs subvolume (manual — requires sudo)

This is a prerequisite that must happen on the live system before the NixOS build. The subvolume must exist for the mount to succeed.

**Step 1: Create the subvolume**

```bash
sudo btrfs subvolume create /mnt/btrfs-root/@games
```

Expected: `Create subvolume '/mnt/btrfs-root/@games'`

**Step 2: Set nocow attribute**

```bash
sudo chattr +C /mnt/btrfs-root/@games
```

**Step 3: Set ownership**

```bash
sudo chown kiper:users /mnt/btrfs-root/@games
```

**Step 4: Create the mount point**

```bash
sudo mkdir -p /games
```

---

### Task 2: Add /games mount to hardware-configuration.nix

**Files:**
- Modify: `hosts/lightspeed/hardware-configuration.nix:100-104` (after /var/lib/docker block)

**Step 1: Add the @games fileSystems entry**

Add after the `/var/lib/docker` block (line 104):

```nix
  fileSystems."/games" = {
    device = "/dev/mapper/cryptbtrfs";
    fsType = "btrfs";
    options = [ "subvol=@games" ] ++ btrfsNoCow;
  };
```

This follows the same pattern as @data and @docker — nodatacow for game I/O performance.

**Step 2: Verify syntax**

Run: `nix flake check 2>&1 | head -5`

---

### Task 3: Add @games exclusion to btrfs.nix btrbk config

**Files:**
- Modify: `nixos/btrfs.nix:35-38` (the comment block listing excluded subvolumes)

**Step 1: Add @games to the exclusion comments**

Change line 38 from:
```nix
        # @swap: not snapshotted
```
to:
```nix
        # @games: not snapshotted — re-downloadable game installs
        # @swap: not snapshotted
```

This documents the intentional exclusion. No btrbk config change needed since btrbk only snapshots explicitly listed subvolumes.

---

### Task 4: Create nixos/gaming.nix module

**Files:**
- Create: `nixos/gaming.nix`

**Step 1: Write the gaming module**

```nix
{ config, pkgs, vars, ... }:

{
  # ── Steam (provides steam-run FHS environment for Wine games) ────
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = false;
  };

  # ── GameMode (CPU governor, nice, GPU perf mode during games) ────
  programs.gamemode.enable = true;

  # ── Gamescope (Wayland micro-compositor for frame pacing, FSR) ──
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  # ── Esync/Fsync file descriptor limits ──────────────────────────
  # Required for Wine synchronization performance. Without this,
  # games using esync will crash or stutter.
  security.pam.loginLimits = [{
    domain = "*";
    type = "hard";
    item = "nofile";
    value = "524288";
  }];

  # ── /games directory permissions ────────────────────────────────
  systemd.tmpfiles.rules = [
    "d /games 0755 ${vars.username} users -"
  ];
}
```

---

### Task 5: Import gaming.nix in lightspeed configuration.nix

**Files:**
- Modify: `hosts/lightspeed/configuration.nix:24` (imports list)

**Step 1: Add gaming.nix import**

Add after the `../../nixos/monitoring.nix` line:

```nix
    ../../nixos/gaming.nix
```

---

### Task 6: Add gaming packages to lightspeed home.nix

**Files:**
- Modify: `hosts/lightspeed/home.nix:34-40` (home.packages block)

**Step 1: Add gaming packages**

Add to the `home.packages` list:

```nix
    # Gaming
    wineWow64Packages.stagingFull  # Wine 32+64-bit with all features
    winetricks                      # Windows dependency installer (vcredist, .NET, fonts)
    lutris                          # Game manager / launcher for non-Steam games
    mangohud                        # FPS/GPU/CPU performance overlay
    protonup-qt                     # Manage Wine-GE/Proton-GE runners
```

---

### Task 7: Build and validate

**Step 1: Test build (no boot entry)**

Run: `nh os test`

Expected: Build completes successfully. Watch for:
- Steam package download (large, ~2GB)
- Wine staging build/download
- Gamescope build

**Step 2: If build succeeds, switch**

Run: `nh os switch`

**Step 3: Verify gaming tools are available**

```bash
which lutris && which wine && which gamemoderun && which gamescope && which mangohud
```

Expected: All five paths resolve.

**Step 4: Verify /games is mounted**

```bash
mount | grep /games
```

Expected: Shows `/dev/mapper/cryptbtrfs on /games type btrfs (... nodatacow ...)`

---

### Task 8: Commit

**Step 1: Stage and commit**

```bash
git add hosts/lightspeed/hardware-configuration.nix \
       hosts/lightspeed/configuration.nix \
       hosts/lightspeed/home.nix \
       nixos/gaming.nix \
       nixos/btrfs.nix
git commit -m "Add gaming support: Wine/Lutris, GameMode, Gamescope, @games subvolume"
```

---

## Post-Setup Usage

### Installing a FitGirl repack:

1. Download repack to `/games/downloads/`
2. Open Lutris → `+` → Add locally installed game
3. Game info: set name
4. Game options: set executable to `setup.exe`, Wine prefix to `/games/<name>/prefix`
5. Runner options: Wine runner (or install Wine-GE via ProtonUp-Qt first)
6. Install → Lutris runs the installer via Wine
7. After install, set the game executable to the installed `.exe`
8. Right-click game → Configure → System options → enable "Enable Feral GameMode"
9. For FPS overlay: set env var `MANGOHUD=1` in system options

### Using gamescope for 4K scaling:

```bash
gamescope -W 2560 -H 1440 -w 3840 -h 2160 -f -- mangohud lutris lutris:rungame/<game-id>
```

Runs the game at 1440p internal, upscaled to 4K with FSR.
