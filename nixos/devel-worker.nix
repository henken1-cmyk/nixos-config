{ config, pkgs, inputs, ... }:

{
  imports = [ inputs.devel-agent.nixosModules.devel-worker ];

  services.devel-worker = {
    enable = true;
    user = "kiper";

    orchestrator.grpc = "http://localhost:42069";

    docker = {
      project = "devel-agent";
      network = "hub_hub-network";
      registry = "philip.nazareth.dev/kiper";
      tag = "latest";
      orchestrator_host = "orchestrator";
      mcp_vm_url = "http://mcp-victoriametrics:8080";
      mcp_loki_url = "http://mcp-loki:8080";
    };

    paths = {
      projects = "/devel";
      inbox = "/devel/.inbox";
      workspaces = "/tmp/agent-workspaces";
      data = "/home/kiper/.local/share/devel-worker";
    };

    observability.otel = "http://localhost:4317";
  };
}
