# Configuration for Cloudflared service
{ config, lib, pkgs, ... }:

{
  # Create cloudflared user and group
  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
    description = "Cloudflared service user";
  };
  
  users.groups.cloudflared = {};

  # Fix permission issues with the config file
  system.activationScripts.cloudflaredPerms = ''
    mkdir -p /etc/cloudflared
    chmod 755 /etc/cloudflared
    chmod 644 /etc/cloudflared/tunnel.json || true
  '';

  services.cloudflared = {
    enable = true;
    tunnels = {
      "3b90d790-0a11-46ae-9421-d195cc828947" = {
        credentialsFile = "/etc/cloudflared/tunnel.json";
        ingress = {
          "up.syscd.live" = "http://localhost:8080";
          "gatus.syscd.live" = "http://localhost:8080";
        };
        default = "http_status:404";
      };
    };
  };

  # Ensure cloudflared only starts after credentials file exists
  systemd.services."cloudflared-tunnel-3b90d790-0a11-46ae-9421-d195cc828947" = {
    unitConfig = {
      ConditionPathExists = "/etc/cloudflared/tunnel.json";
    };

    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };
} 
