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
    powerManagement.enable = false; # Desktop, not laptop
    powerManagement.finegrained = false;
    open = true; # RTX 3090 Ti (Ampere) — open kernel modules
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
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
    [ "nvidia" "nvidia_modeset" "nvidia_drm" ];
  boot.kernelParams = [ "nvidia-drm.modeset=1" "nvidia-drm.fbdev=1" ];

  # NVENC for gpu-screen-recorder
  environment.systemPackages = with pkgs; [
    nvidia-vaapi-driver
    libva
    libva-utils
  ];
}
