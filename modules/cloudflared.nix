# Configuration for Cloudflared service
{ config, lib, pkgs, ... }:

{
  # Fix permission issues with the config file
  system.activationScripts.cloudflaredPerms = ''
    mkdir -p /etc/cloudflared
    chmod 755 /etc/cloudflared
    chmod 644 /etc/cloudflared/config.json || true
  '';

  services.cloudflared = {
    enable = true;
    tunnels = {
      "3b90d790-0a11-46ae-9421-d195cc828947" = {
        # credentialsFile = "${config.sops.secrets.cloudflared-creds.path}";
        credentialsFile = "/etc/cloudflared/config.json";
        ingress = {
          "up2.syscd.live" = "http://localhost:8080";
        };
        default = "http_status:404";
      };
    };
  };
} 