{
  description = "NixOS Bonkers Setup — lightspeed, adam & henkenit";

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

    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.astal.follows = "astal";
    };

    astal = {
      url = "github:aylur/astal";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprpanel = {
      url = "github:henken1-cmyk/HyprPanel";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, stylix, nixvim, sops-nix, firefox-addons, claude-code, nix-flatpak, ags, astal, hyprpanel, ... }@inputs:
    let
      lightspeedVars = import ./hosts/lightspeed/variables.nix;
      adamVars = import ./hosts/adam/variables.nix;
      henkenitVars = import ./hosts/henkenit/variables.nix;
    in
    {
      nixosConfigurations.lightspeed = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; vars = lightspeedVars; };
        modules = [
          ./hosts/lightspeed/configuration.nix
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
          stylix.nixosModules.stylix
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          nix-flatpak.nixosModules.nix-flatpak
          {
            nixpkgs.config.allowUnfree = true;
            nixpkgs.overlays = [
              (final: prev: {
                hyprpanel = hyprpanel.packages.${prev.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
                  postPatch = (old.postPatch or "") + ''
                    cp ${./patches/prometheus.scss} src/style/scss/menus/prometheus.scss
                    cp ${./patches/media-launch-buttons.tsx} src/components/menus/media/components/LaunchButtons.tsx
                    cp ${./patches/media-index.tsx} src/components/menus/media/index.tsx
                    cat ${./patches/media-launch-buttons.scss} >> src/style/scss/menus/media.scss
                  '';
                });
              })
            ];
          }
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

      nixosConfigurations.henkenit = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; vars = henkenitVars; };
        modules = [
          ./hosts/henkenit/configuration.nix
          stylix.nixosModules.stylix
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          nix-flatpak.nixosModules.nix-flatpak
          {
            nixpkgs.config.allowUnfree = true;
            nixpkgs.overlays = [
              (final: prev: {
                hyprpanel = hyprpanel.packages.${prev.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
                  postPatch = (old.postPatch or "") + ''
                    cp ${./patches/prometheus.scss} src/style/scss/menus/prometheus.scss
                    cp ${./patches/media-launch-buttons.tsx} src/components/menus/media/components/LaunchButtons.tsx
                    cp ${./patches/media-index.tsx} src/components/menus/media/index.tsx
                    cat ${./patches/media-launch-buttons.scss} >> src/style/scss/menus/media.scss
                  '';
                });
              })
            ];
          }
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs; vars = henkenitVars; };
              users.${henkenitVars.username} = import ./hosts/henkenit/home.nix;
            };
          }
        ];
      };
    };
}
