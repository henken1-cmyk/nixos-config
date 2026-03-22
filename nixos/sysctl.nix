{ config, pkgs, ... }:

{
  # Increase file watcher limit (default 8192 is too low for dev tools)
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 524288;
    "fs.inotify.max_user_instances" = 1024;
  };

  # Faster shutdown — don't wait 90s for hanging services
  systemd.settings.Manager.DefaultTimeoutStopSec = "10s";

  # Kill user sessions quickly on shutdown (lingering graphical sessions)
  systemd.settings.Manager.DefaultTimeoutAbortSec = "10s";

  # Ensure Docker daemon doesn't block shutdown for ages
  systemd.services.docker.serviceConfig.TimeoutStopSec = "15s";

  # ── Fast shutdown: kill user session processes ─────────────────────
  # Kill all user processes on logout/shutdown (prevents UID 1000 blocking)
  services.logind.killUserProcesses = true;

  # Limit how long inhibitor locks (e.g. "app is saving") can delay shutdown
  services.logind.settings.Login.InhibitDelayMaxSec = 5;

  # Don't linger user services after session ends
  services.logind.settings.Login.UserStopDelaySec = 0;
}
