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

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-desktop = {
      url = "github:aaddrick/claude-desktop-debian";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ghostty = {
      url = "git+file:///devel/ghostty";
    };

    devel-agent = {
      url = "git+file:///devel/devel-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
    };

    hyprpanel = {
      url = "github:henken1-cmyk/HyprPanel";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    voicebox-mcp = {
      url = "git+file:///devel/voicebox_mcp";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, stylix, nixvim, sops-nix, firefox-addons, claude-code, nix-flatpak, spicetify-nix, hyprland, claude-desktop, ghostty, devel-agent, nix-cachyos-kernel, hyprpanel, hermes-agent, voicebox-mcp, ... }@inputs:
    let
      scale = import ./themes/scale.nix;
      lightspeedVars = import ./hosts/lightspeed/variables.nix;
      adamVars = import ./hosts/adam/variables.nix;
      henkenitVars = import ./hosts/henkenit/variables.nix;

      # HyprPanel overlay applies our Spotify/YT-Music + Prometheus patches.
      # Shared by all hosts that use HyprPanel.
      hyprpanelOverlay = (final: prev: {
        hyprpanel = hyprpanel.packages.${prev.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
          postPatch = (old.postPatch or "") + ''
            cp ${./patches/prometheus.scss} src/style/scss/menus/prometheus.scss
            cp ${./patches/media-launch-buttons.tsx} src/components/menus/media/components/LaunchButtons.tsx
            cp ${./patches/media-index.tsx} src/components/menus/media/index.tsx
            cat ${./patches/media-launch-buttons.scss} >> src/style/scss/menus/media.scss
          '';
        });
      });

      # nixpkgs hyprlock is stuck at 0.9.2 (Oct 2025). Upstream is 0.9.5 with three
      # fixes for crashes seen on this machine:
      #   PR #884 (in 0.9.3) — destroy renderer before EGL teardown (NVIDIA exit crash)
      #   PR #988 (in 0.9.4) — lock-surface egl window/surface creation race
      #   PR #992/#994 (in 0.9.5) — dmabuf/egl thread handling
      # Remove this overlay once nixpkgs bumps past 0.9.5.
      hyprlockOverlay = (final: prev: {
        hyprlock = prev.hyprlock.overrideAttrs (old: rec {
          version = "0.9.5";
          src = prev.fetchFromGitHub {
            owner = "hyprwm";
            repo = "hyprlock";
            rev = "v${version}";
            hash = "sha256-VFlM1cN4jmUAbfmZbeg7vL+AN9miXEUqqpk5EkHNq2c=";
          };
        });
      });
    in
    {
      nixosConfigurations.lightspeed = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs scale; vars = lightspeedVars; };
        modules = [
          ./hosts/lightspeed/configuration.nix
          hyprland.nixosModules.default
          stylix.nixosModules.stylix
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          nix-flatpak.nixosModules.nix-flatpak
          hermes-agent.nixosModules.default
          { nixpkgs.config.allowUnfree = true;
            nixpkgs.overlays = [ ghostty.overlays.default nix-cachyos-kernel.overlays.pinned hyprpanelOverlay hyprlockOverlay ];
          }
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              # KDE Plasma rewrites ~/.gtkrc-2.0 on every session start; without
              # a backup extension, the next HM activation hard-fails.
              backupFileExtension = "hm-backup";
              extraSpecialArgs = { inherit inputs scale; vars = lightspeedVars; };
              users.${lightspeedVars.username} = import ./hosts/lightspeed/home.nix;
            };
          }
        ];
      };

      nixosConfigurations.adam = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs scale; vars = adamVars; };
        modules = [
          ./hosts/adam/configuration.nix
          hyprland.nixosModules.default
          stylix.nixosModules.stylix
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          nix-flatpak.nixosModules.nix-flatpak
          {
            nixpkgs.config.allowUnfree = true;
            nixpkgs.overlays = [ hyprpanelOverlay hyprlockOverlay ];
          }
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs scale; vars = adamVars; };
              users.${adamVars.username} = import ./hosts/adam/home.nix;
            };
          }
        ];
      };

      nixosConfigurations.henkenit = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs scale; vars = henkenitVars; };
        modules = [
          ./hosts/henkenit/configuration.nix
          hyprland.nixosModules.default
          stylix.nixosModules.stylix
          home-manager.nixosModules.home-manager
          sops-nix.nixosModules.sops
          nix-flatpak.nixosModules.nix-flatpak
          {
            nixpkgs.config.allowUnfree = true;
            nixpkgs.overlays = [ hyprpanelOverlay hyprlockOverlay ];
          }
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit inputs scale; vars = henkenitVars; };
              users.${henkenitVars.username} = import ./hosts/henkenit/home.nix;
            };
          }
        ];
      };
    };
}
