{ config, pkgs, lib, vars, ... }:

{
  # NVIDIA proprietary drivers
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    # VA-API driver goes here so it's linked into /run/opengl-driver/lib/dri/
    # — every libva-aware app (Firefox, Chromium, mpv, OBS, ffmpeg…) finds it
    # via LIBVA_DRIVER_NAME=nvidia. Listing in environment.systemPackages is
    # NOT enough; libva only scans /run/opengl-driver.
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
    ];
  };

  # CLI tools for VA-API verification (vainfo etc.) — only needed in PATH,
  # not in the driver lookup path.
  environment.systemPackages = with pkgs; [
    libva-utils
  ];

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true; # Required for hibernate/resume GPU state
    powerManagement.finegrained = false;
    open = vars.nvidiaOpen or true; # Turing+ (RTX 3090 Ti, RTX 5070 Ti) — open kernel modules
    nvidiaSettings = true;
    package =
      let base = config.boot.kernelPackages.nvidiaPackages.stable; in
      if (vars.nvidiaHibernatePatch or false)
      then base // {
        open = base.open.overrideAttrs (old: {
          patches = (old.patches or []) ++ [ ./patches/nvidia-hibernate-resume.patch ];
        });
      }
      else base;
  };

  # Wayland + NVIDIA env vars.
  # __GL_VRR_ALLOWED / __GL_GSYNC_ALLOWED intentionally omitted — they trigger
  # NVIDIA/open-gpu-kernel-modules#990 (atomic-modeset failures) in KWin on Plasma 6.
  environment.sessionVariables = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
  };

  # NVIDIA early load: in initrd for Plymouth on NVIDIA fb, unless ESP too small
  boot.initrd.kernelModules = lib.optionals (vars.gpuInInitrd or true)
    [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
  # nvidia-drm.fbdev=1 (NVIDIA kernel framebuffer console) holds a DRM lease
  # that races with KWin at SDDM→Plasma handoff and on every DPMS cycle, causing
  # "drmModeListLessees() failed: Permission denied" and "Atomic modeset test
  # failed!" — symptoms include stutter on resume + multi-monitor weirdness.
  # Dropped here in exchange for a text-mode early console (no Plymouth used).
  boot.kernelParams = [ "nvidia-drm.modeset=1" ];

}
