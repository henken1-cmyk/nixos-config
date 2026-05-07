{ config, pkgs, lib, vars, ... }:

{
  # NVIDIA proprietary drivers
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

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

  # Wayland + NVIDIA env vars
  environment.sessionVariables = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";
  };

  # NVIDIA early load: in initrd for Plymouth on NVIDIA fb, unless ESP too small
  boot.initrd.kernelModules = lib.optionals (vars.gpuInInitrd or true)
    [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
  boot.kernelParams = [ "nvidia-drm.modeset=1" "nvidia-drm.fbdev=1" ];

  # NVENC for gpu-screen-recorder
  environment.systemPackages = with pkgs; [
    nvidia-vaapi-driver
    libva
    libva-utils
  ];
}
