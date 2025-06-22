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
    useRoutingFeatures = "both"; # Enable Tailscale subnet routing
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
      ${tailscale}/bin/tailscale up -authkey $(cat /etc/tailscale/tailscale-auth.key) --accept-dns --accept-routes
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

  # DNS configuration for Tailscale MagicDNS integration
  # unbound acts as a local DNS forwarder to handle both Tailscale and regular DNS queries:
  # - Tailscale domains (*.ts.net) are forwarded to Tailscale's DNS (100.100.100.100)
  # - All other domains are forwarded to public DNS (8.8.8.8)
  # This allows seamless resolution of Tailscale device hostnames while maintaining internet DNS
  services.unbound = {
    enable = true;
    settings = {
      server = {
        interface = "127.0.0.1";
        access-control = "127.0.0.0/8 allow";
        do-not-query-localhost = "no";
      };
      forward-zone = [
        {
          name = "tailcecc0.ts.net";
          forward-addr = "100.100.100.100";
        }
        {
          name = ".";
          forward-addr = [
            "8.8.8.8"
            "8.8.4.4"
            "1.1.1.1"
            "1.0.0.1"
          ];
        }
      ];
    };
  };

  networking.nameservers = [ "127.0.0.1" ];
}
