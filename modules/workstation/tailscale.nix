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

  # Trust the tailnet interface so every dev-server port is reachable from
  # tailnet devices without per-port firewall openings (design.md §5).
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
