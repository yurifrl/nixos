# Cloudflare Tunnel for the workstation's *.syscd.space dev apps.
#
# The connector runs HERE, on the VM, next to the apps it fronts, and dials
# them over loopback. This is the same host-level pattern as
# modules/foundry/cloudflared.nix and modules/gatus/cloudflared.nix -- the
# connector belongs with the origin, not in the cluster. Running it in-cluster
# would add a needless cluster->LAN->VM hop and, worse, tie "reach my VM app"
# to cluster health (a single NotReady node took the whole path down).
#
# Tunnel: syscd-apps (dedicated, isolated from the nixos-1 *.syscd.live SPOF).
# DNS: *.syscd.space CNAME -> <tunnelId>.cfargotunnel.com, managed declaratively
#      by external-dns (home-systems k8s/charts/dns-records). Any hostname the
#      ingress below knows is served; everything else gets a 404.
#
# To expose another local app: add one `"<app>.syscd.space" = "http://localhost:<port>";`
# line to the ingress. No new tunnel, no new DNS (the wildcard already resolves).
#
# Credentials: /etc/cloudflared/tunnel.json is seeded from 1Password
# (workstation item, CLOUDFLARED_TUNNEL_JSON field) by the box's provisioning,
# exactly like /etc/tailscale/authkey. cloudflared waits for the file to exist.
{ config, lib, pkgs, ... }:
let
  tunnelId = "c8196d6d-a1b8-4e80-9f7b-c06450e462a2";
  credentialsFile = "/etc/cloudflared/tunnel.json";
in
{
  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
  };
  users.groups.cloudflared = { };

  system.activationScripts.workstationCloudflaredPerms = ''
    mkdir -p /etc/cloudflared
    chmod 755 /etc/cloudflared
    chmod 640 ${credentialsFile} || true
  '';

  services.cloudflared = {
    enable = true;
    tunnels.${tunnelId} = {
      inherit credentialsFile;
      ingress = {
        "board-games.syscd.space" = "http://localhost:8080";
        # herdr remote access. herdr-phone (external mode) serves the origin on
        # loopback and re-validates the Cloudflare Access JWT this connector
        # passes through; see modules/workstation/herdr-phone.nix.
        "herdr.syscd.space" = "http://localhost:8787";
      };
      default = "http_status:404";
    };
  };

  systemd.services."cloudflared-tunnel-${tunnelId}" = {
    unitConfig.ConditionPathExists = credentialsFile;
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };
}
