{
  description = "NixOS Bonkers Setup — lightspeed & adam";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix.url = "github:danth/stylix";

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, stylix, nixvim, sops-nix, firefox-addons, claude-code, nix-flatpak, spicetify-nix, hyprland, ... }@inputs:
    let
      lightspeedVars = import ./hosts/lightspeed/variables.nix;
      adamVars = import ./hosts/adam/variables.nix;
    in
    {
      nixosConfigurations.lightspeed = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; vars = lightspeedVars; };
        modules = [
          ./hosts/lightspeed/configuration.nix
          hyprland.nixosModules.default
          stylix.nixosModules.stylix
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          nix-flatpak.nixosModules.nix-flatpak
          { nixpkgs.config.allowUnfree = true; }
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs; vars = lightspeedVars; };
              users.${lightspeedVars.username} = import ./hosts/lightspeed/home.nix;
            };
          }
        ];
      };

      nixosConfigurations.adam = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; vars = adamVars; };
        modules = [
          ./hosts/adam/configuration.nix
          hyprland.nixosModules.default
          stylix.nixosModules.stylix
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          nix-flatpak.nixosModules.nix-flatpak
          { nixpkgs.config.allowUnfree = true; }
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs; vars = adamVars; };
              users.${adamVars.username} = import ./hosts/adam/home.nix;
            };
          }
        ];
      };
    };
}
