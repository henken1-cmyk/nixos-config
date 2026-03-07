{ config, pkgs, lib, vars, ... }:

{
  # Disable PulseAudio (PipeWire replaces it)
  services.pulseaudio.enable = false;

  # PipeWire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  # Keep S/PDIF optical link alive (prevent 5s re-negotiation delay)
  services.pipewire.wireplumber.extraConfig."50-spdif-no-suspend" =
    lib.mkIf (vars ? spdifNodeName && vars.spdifNodeName != null) {
      "monitor.alsa.rules" = [{
        matches = [{ "node.name" = vars.spdifNodeName; }];
        actions.update-props = {
          "session.suspend-timeout-seconds" = 0;
        };
      }];
    };

  environment.systemPackages = with pkgs; [
    pavucontrol # GUI audio mixer
    pamixer # CLI volume control (for keybinds)
  ];
}
