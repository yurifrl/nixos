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
        credentialsFile = "/etc/cloudflared/config.json";
        ingress = {
          "up.syscd.live" = "http://localhost:8080";
          "up.syscd.tech" = "http://localhost:8080";
          "up.syscd.xyz" = "http://localhost:8080";
          "gatus.syscd.live" = "http://localhost:8080";
          "gatus.syscd.tech" = "http://localhost:8080";
          "gatus.syscd.xyz" = "http://localhost:8080";
        };
        default = "http_status:404";
      };
    };
  };
} 