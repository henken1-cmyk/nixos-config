{ config, pkgs, vars, ... }:

{
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      trusted-users = [ "root" vars.username ];
      download-buffer-size = 268435456; # 256 MiB
      max-jobs = 4;   # max 4 parallel derivations (prevents OOM from heavy builds like CUDA)
      cores = 4;      # max 4 cores per derivation
      substituters = [
        "https://cache.nixos.org"
        "https://hyprland.cachix.org"
        "https://cuda-maintainers.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      ];
    };

  };

  # nh (nix helper) for prettier builds
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep 5 --keep-since 3d";
    flake = "/home/${vars.username}/.config/nixos";
  };

  # nix-ld — provides /lib64/ld-linux-x86-64.so.2 so downloaded dynamically
  # linked binaries (e.g. Claude Desktop's VM workspace agent, pip wheels) can run
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # CUDA (PyTorch, JAX, etc.)
    cudaPackages.cudatoolkit
    cudaPackages.cudnn
    cudaPackages.nccl
    # Common native deps for Python wheels
    stdenv.cc.cc.lib  # libstdc++
    zlib
  ];

  # /bin/bash — many external scripts hardcode #!/bin/bash (e.g. Claude Code plugins)
  system.activationScripts.binbash = {
    deps = [ "binsh" ];
    text = ''
      ln -sf /bin/sh /bin/bash
    '';
  };

  environment.systemPackages = with pkgs; [
    nix-output-monitor # nom - pretty build output
  ];
}
