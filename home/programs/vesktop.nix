# Vesktop — Discord client with Vencord, GPU-accelerated on NVIDIA Wayland
{ config, pkgs, lib, ... }:

let
  electronFeatures = lib.concatStringsSep "," [
    "VaapiVideoDecodeLinuxGL"
    "AcceleratedVideoDecoder"
    "AcceleratedVideoDecodeLinuxGL"
    "AcceleratedVideoDecodeLinuxZeroCopyGL"
    "AcceleratedVideoEncoder"
    "WebRTCPipeWireCapturer"
  ];

  vesktop-gpu = pkgs.vesktop.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      wrapProgram $out/bin/vesktop \
        --add-flags "--enable-features=${electronFeatures}" \
        --add-flags "--ignore-gpu-blocklist"
    '';
  });
in
{
  home.packages = [ vesktop-gpu ];
}
