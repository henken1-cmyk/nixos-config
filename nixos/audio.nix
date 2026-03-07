{ config, pkgs, ... }:

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
  services.pipewire.wireplumber.extraConfig."50-spdif-no-suspend" = {
    "monitor.alsa.rules" = [{
      matches = [{ "node.name" = "alsa_output.pci-0000_0d_00.4.iec958-stereo"; }];
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
