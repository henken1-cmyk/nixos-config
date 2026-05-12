{ config, lib, ... }:

{
  # Upstream module exports HERMES_HOME=/var/lib/hermes/.hermes into
  # /etc/set-environment, which breaks every non-hermes user's CLI
  # (the service state dir is hermes:hermes 0640). Redirect interactive
  # shells to per-user ~/.hermes. The systemd unit sets HERMES_HOME
  # directly in its Environment= block, so the service is unaffected.
  environment.variables.HERMES_HOME = lib.mkForce "$HOME/.hermes";

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;

    settings = {
      model = {
        provider = "anthropic";
        default = "claude-sonnet-4-6";
      };

      custom_providers = [
        {
          name = "local";
          base_url = "http://localhost:8081/v1";
          models = {
            local-llama-mtp = {
              context_length = 131072;
            };
          };
        }
      ];
    };

    # Root-readable env file. Keys live here (not in nix store / not in git):
    #   ANTHROPIC_API_KEY=sk-ant-...
    #   OPENROUTER_API_KEY=sk-or-v1-...
    # Local llama.cpp on :8081 needs no key.
    # Create with:
    #   sudo install -d -m 700 /var/lib/hermes
    #   sudoedit /var/lib/hermes/env
    #   sudo chmod 600 /var/lib/hermes/env
    environmentFiles = [ "/var/lib/hermes/env" ];
  };

  # Hermes drains in-flight tasks for up to 180s on stop; give systemd
  # enough headroom so it doesn't SIGKILL the gateway mid-drain.
  systemd.services.hermes-agent.serviceConfig.TimeoutStopSec = 210;
}
