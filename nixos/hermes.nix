{ config, pkgs, inputs, ... }:

let
  voicebox = inputs.voicebox-mcp.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;

    settings = {
      model = {
        provider = "custom";
        base_url = "http://localhost:8081/v1";
        default = "local-llama-mtp";
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

      # Hub-hosted MCP servers (SSE transport via Traefik).
      # The nixos module's `mcpServers` option lacks a `transport` field,
      # so we set them under settings.mcp_servers directly — the merger
      # treats this as freeform attrs and passes `transport: sse` through
      # to hermes's MCP client, which dispatches the SSE handler.
      # Backends live in /devel/hub/docker-compose.yml.
      mcp_servers = {
        forgejo = {
          url = "https://mcp-forgejo.nazareth.dev/sse";
          transport = "sse";
        };
        victoriametrics = {
          url = "https://mcp-vm.nazareth.dev/sse";
          transport = "sse";
        };
        loki = {
          url = "https://mcp-loki.nazareth.dev/sse";
          transport = "sse";
        };
      };
    };

    # stdio MCP servers — typed via the module's mcpServers option.
    mcpServers = {
      # Local TTS (Kokoro). Audio is per-user PipeWire (socket in
      # /run/user/1000/), so the subprocess has to run as kiper to reach
      # the speakers — hermes (the service user) has no audio session.
      # We invoke via `sudo -u kiper` so PAM sets XDG_RUNTIME_DIR and
      # voicebox's PortAudio→PipeWire chain Just Works. NOPASSWD rule
      # for this exact binary is declared below.
      voicebox = {
        command = "/run/wrappers/bin/sudo";
        args = [ "-n" "-H" "-u" "kiper" "${voicebox}/bin/voicebox-mcp" ];
      };
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

  # Let the hermes service spawn voicebox-mcp as kiper without a password
  # so the TTS subprocess inherits kiper's PipeWire session (via PAM's
  # XDG_RUNTIME_DIR). Pinned to the exact store path; rebuild updates it.
  security.sudo.extraRules = [{
    users = [ "hermes" ];
    runAs = "kiper";
    commands = [{
      command = "${voicebox}/bin/voicebox-mcp";
      options = [ "NOPASSWD" ];
    }];
  }];
}
