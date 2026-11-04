# Tailscale for the workstation dev VM.
# Uses the native NixOS tailscale module (not the shared custom autoconnect):
# tailscaled runs and authenticates from the authkey that workstation-bootstrap.sh
# op-reads to /etc/tailscale/authkey. The authkey is minted tag:workstation, and
# we also advertise the tag explicitly.
{ ... }:
{
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    # Path matches workstation-bootstrap.sh TS_AUTHKEY_FILE.
    authKeyFile = "/etc/tailscale/authkey";
    extraUpFlags = [
      "--advertise-tags=tag:workstation"
      "--ssh"
      "--accept-dns"
      "--accept-routes"
    ];
  };

  # design.md §5 gotcha #1: dev servers must bind 0.0.0.0, not 127.0.0.1, or
  # they are invisible over the tailscale interface. Set the common convention
  # var globally so `HOST`-aware dev servers bind wide by default.
  environment.variables.HOST = "0.0.0.0";

  # The tailnet advertises the home LAN (192.168.68.0/24) as a subnet route;
  # accepting it installs that route in table 52, which ip rule 5270 consults
  # BEFORE the main table — so replies to LAN peers (Moonlight, the Mac's
  # browser) get diverted into the tailnet and never arrive, while
  # tailnet-originated traffic (SSH via 100.x) still works. Pin ONLY the
  # home-LAN prefix back to the main table, ahead of rule 5270: the ens18
  # connected route serves LAN peers again, and every other accepted subnet
  # (10.x company ranges) keeps routing via the tailnet.
  networking.localCommands = ''
    ip rule add priority 5265 to 192.168.68.0/24 lookup main 2>/dev/null || true
  '';

  # Trust the tailnet interface so every dev-server port is reachable from
  # tailnet devices without per-port firewall openings (design.md §5).
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
