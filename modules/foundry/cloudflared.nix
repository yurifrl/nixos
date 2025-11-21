# Cloudflare Tunnel configuration for Foundry VTT
{ config, lib, pkgs, ... }:

{
  # Note: This uses a separate Cloudflare Tunnel from Gatus
  # The tunnel ID and credentials must be created separately and provided as secrets

  # Fix permission issues with the config file
  system.activationScripts.foundryCloudflaredPerms = ''
    mkdir -p /etc/cloudflared
    chmod 755 /etc/cloudflared
    chmod 644 /etc/cloudflared/foundry-tunnel.json || true
  '';

  services.cloudflared = {
    enable = true;
    tunnels = {
      # TODO: Replace with actual Foundry tunnel ID after creation
      # Create tunnel with: cloudflare tunnel create foundry
      "foundry-tunnel-id-placeholder" = {
        credentialsFile = "/etc/cloudflared/foundry-tunnel.json";
        ingress = {
          "foundry.syscd.live" = "http://localhost:30000";
          "foundry.syscd.tech" = "http://localhost:30000";
        };
        default = "http_status:404";
      };
    };
  };
}
