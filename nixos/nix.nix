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
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };

  };

  # nh (nix helper) for prettier builds
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.dates = "daily"; # Run cleanup daily via timer, not at boot
    clean.extraArgs = "--keep 5 --keep-since 3d";
    flake = "/home/${vars.username}/.config/nixos";
  };

  environment.systemPackages = with pkgs; [
    nix-output-monitor # nom - pretty build output
  ];
}
