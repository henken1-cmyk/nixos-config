# Fibonacci design tokens — golden-ratio visual harmony
# Sequence: 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987
#
# Access in modules: { scale, ... }: scale.gap.md
# In CSS strings: "${scale.px scale.font.md}" → "21px"
{
  # Helper for CSS interpolation
  px = v: "${toString v}px";

  # ── Spacing (padding, margins, gaps) ──
  gap = {
    xxs = 2;   xs = 3;   sm = 5;   md = 8;
    lg = 13;   xl = 21;  xxl = 34; xxxl = 55;
  };

  # ── Border radius ──
  radius = {
    sm = 5;  md = 8;  lg = 13;  xl = 21;  pill = 34;
  };

  # ── Border width ──
  border = { thin = 1; normal = 2; thick = 3; };

  # ── Font sizes ──
  # Stylix (points): sm=13 for body text
  # CSS (pixels at 4K): md=21 for body text
  font = {
    xs = 8;   sm = 13;  md = 21;  lg = 34;
    xl = 55;  display = 89;  hero = 144;
  };

  # ── Icon sizes ──
  icon = { sm = 13; md = 21; lg = 34; };

  # ── Component heights ──
  size = {
    cursor = 34;  bar = 55;  input = 55;  toggle = 34;
  };

  # ── Container dimensions ──
  container = {
    notification = 377;
    panel = 610;
    window = 987;
    panelHeight = 610;
    notificationH = 144;
  };
}
