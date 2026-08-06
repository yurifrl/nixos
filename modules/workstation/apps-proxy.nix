# Expose selected dev-app ports on the LAN interface so the in-cluster
# *.syscd.space cloudflared proxy (home-systems `apps-space` chart) can reach the
# apps running on this box. tailscale.nix trusts only tailscale0, but the Talos
# cluster reaches the workstation over the LAN (same L2, 192.168.68.0/24), so the
# proxied app ports must also be open on the LAN interface.
#
# Keep this list in sync with the `apps` map in
# home-systems-values/apps-space/values.yaml (name -> port).
{ ... }:
{
  networking.firewall.allowedTCPPorts = [
    8080 # board-games
  ];
}
