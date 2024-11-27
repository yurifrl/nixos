{ pkgs, pkgs-unstable, ... }:
{
  environment.systemPackages = with pkgs; [
    jq
    pkgs-unstable.tailscale
  ];

  # Tailscale service configuration
  services.tailscale = {
    enable = true;
    package = pkgs-unstable.tailscale;
  };

  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";

    # make sure tailscale is running before trying to connect to tailscale
    after = [
      "network-pre.target"
      "tailscale.service"
    ];
    wants = [
      "network-pre.target"
      "tailscale.service"
    ];
    wantedBy = [ "multi-user.target" ];

    # set this service as a oneshot job
    serviceConfig.Type = "oneshot";

    # have the job run this shell script
    script = with pkgs; ''
      # wait for tailscaled to settle
      sleep 2

      # check if we are already authenticated to tailscale
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then # if so, then do nothing
        exit 0
      fi

      # otherwise authenticate with tailscale and accept DNS
      ${tailscale}/bin/tailscale up -authkey $(cat /etc/tailscale/auth.key) --accept-dns --accept-routes
    '';
  };

  # Tailscale user and group creation
  users = {
    users.tailscale = {
      isNormalUser = true;
      group = "tailscale";
    };
    groups.tailscale = { };
  };

  networking = {
    nameservers = [ "100.100.100.100" ];  # Tailscale MagicDNS
    search = [ "tailcecc0.ts.net" ];      # Your tailnet domain
    firewall = {
      interfaces."tailscale0" = {
        allowedTCPPorts = [ 80 443 ];         # Allow HTTP traffic
      };
    };
  };
}
