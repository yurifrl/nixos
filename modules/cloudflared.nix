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
      "5ce2f91a-f98f-49d1-a966-5c0742f2bddc" = {
        # credentialsFile = "${config.sops.secrets.cloudflared-creds.path}";
        credentialsFile = "/etc/cloudflared/config.json";
        ingress = {
          "up2.syscd.live" = "http://localhost:80";
        };
        default = "http_status:404";
      };
    };
  };
} 