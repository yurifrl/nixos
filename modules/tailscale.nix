{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    jq
    tailscale
  ];

  system.activationScripts.tailscalePerms = ''
    mkdir -p /etc/tailscale
    chmod 755 /etc/tailscale
    chmod 600 /etc/tailscale/tailscale-auth.key || true
  '';

  # Tailscale service configuration
  services.tailscale = {
    enable = true;
    package = pkgs.tailscale;
  };

  # Configure firewall for Tailscale
  networking.firewall = {
    # If firewall is enabled, ensure Tailscale traffic is allowed
    trustedInterfaces = [ "tailscale0" ];
    
    # Allow the Tailscale UDP port through the firewall
    allowedUDPPorts = [ 
      config.services.tailscale.port 
      3478  # Tailscale needs this port for STUN
    ];
    
    # Important: Allow established connections
    allowedUDPPortRanges = [
      { from = 1024; to = 65535; }
    ];
  };

  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";

    # make sure tailscale is running before trying to connect to tailscale
    after = [
      "network-pre.target"
      "tailscale.service" 
      "network-online.target"  # Ensure network is fully online
    ];
    wants = [
      "network-pre.target"
      "tailscale.service" 
      "network-online.target"  # Ensure network is fully online
    ];
    wantedBy = [ "multi-user.target" ];

    # set this service as a oneshot job
    serviceConfig = {
      Type = "oneshot";
      # Add restart strategy for more reliability
      Restart = "on-failure";
      RestartSec = "5s";
    };

    # have the job run this shell script
    script = with pkgs; ''
      # wait for tailscaled to settle - increase for cloud environments
      sleep 5

      # check if we are already authenticated to tailscale
      status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
      if [ $status = "Running" ]; then # if so, then do nothing
        exit 0
      fi

      # otherwise authenticate with tailscale and accept DNS
      # Add --accept-dns flag to ensure proper DNS resolution in cloud
      ${tailscale}/bin/tailscale up -authkey $(cat /etc/tailscale/tailscale-auth.key) --accept-dns
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
}
