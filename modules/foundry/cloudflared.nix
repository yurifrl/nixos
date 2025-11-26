# Cloudflare Tunnel configuration for Foundry VTT
{ config, lib, pkgs, ... }:

{
  # Note: This uses a separate Cloudflare Tunnel from Gatus
  # The tunnel ID and credentials must be created separately and provided as secrets

  # Ensure cloudflared user exists for secrets loading
  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
  };
  users.groups.cloudflared = {};

  # Fix permission issues with the config file
  system.activationScripts.foundryCloudflaredPerms = ''
    mkdir -p /etc/cloudflared
    chmod 755 /etc/cloudflared
    chmod 644 /etc/cloudflared/tunnel.json || true
  '';

  services.cloudflared = {
    enable = true;
    tunnels = {
      "8bc2858c-a6a4-474f-9287-5af2c1928578" = {
        credentialsFile = "/etc/cloudflared/tunnel.json";
        ingress = {
          "rpg.syscd.live" = "http://localhost:30000";
          "foundry.syscd.live" = "http://localhost:30000";
          # Add more hostnames here if needed
        };
        default = "http_status:404";
      };
    };
  };

  # Ensure cloudflared only starts after credentials file exists
  systemd.services."cloudflared-tunnel-8bc2858c-a6a4-474f-9287-5af2c1928578" = {
    unitConfig = {
      ConditionPathExists = "/etc/cloudflared/tunnel.json";
    };

    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };
}
