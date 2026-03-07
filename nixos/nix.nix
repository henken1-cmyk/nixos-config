{ config, pkgs, vars, ... }:

{
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      trusted-users = [ "root" vars.username ];
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
