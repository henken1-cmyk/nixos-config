{ inputs, pkgs, ... }:

{
  imports = [ inputs.ags.homeManagerModules.default ];

  programs.ags = {
    enable = true;
    configDir = ../ags-bar;
    extraPackages = [
      pkgs.libsoup_3
      inputs.astal.packages.${pkgs.stdenv.hostPlatform.system}.hyprland
      inputs.astal.packages.${pkgs.stdenv.hostPlatform.system}.mpris
      inputs.astal.packages.${pkgs.stdenv.hostPlatform.system}.wireplumber
      inputs.astal.packages.${pkgs.stdenv.hostPlatform.system}.battery
      inputs.astal.packages.${pkgs.stdenv.hostPlatform.system}.network
      inputs.astal.packages.${pkgs.stdenv.hostPlatform.system}.bluetooth
      inputs.astal.packages.${pkgs.stdenv.hostPlatform.system}.tray
      inputs.astal.packages.${pkgs.stdenv.hostPlatform.system}.notifd
    ];
  };
}
