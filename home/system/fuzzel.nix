{ config, pkgs, scale, ... }:

{
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        # Font set by Stylix
        terminal = "ghostty -e";
        prompt = "❯ ";
        placeholder = "Search...";
        layer = "overlay";
        width = 45;
        lines = 10;
        horizontal-pad = scale.gap.xxl;
        vertical-pad = scale.gap.xl;
        inner-pad = scale.gap.lg;
        icon-theme = "Papirus";
        image-size-ratio = 0.7;
        match-counter = true;
        line-height = scale.size.toggle;
        letter-spacing = 1;
        use-bold = true;
      };
      border = {
        width = scale.border.thick;
        radius = scale.radius.lg;
      };
      dmenu = {
        exit-immediately-if-empty = true;
      };
      # Colors handled by Stylix
    };
  };
}
