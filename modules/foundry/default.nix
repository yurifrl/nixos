{ config, pkgs, ... }:
{
  # Enable Docker for running Foundry container
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };

  # Create foundry user and group
  users.users.foundry = {
    isSystemUser = true;
    group = "foundry";
    description = "Foundry VTT service user";
    uid = 1000; # Matches typical container user
  };

  users.groups.foundry = {
    gid = 1000;
  };

  # Ensure directory permissions for volume mount
  system.activationScripts.foundryPerms = ''
    mkdir -p /mnt/foundry-data
    chown 1000:1000 /mnt/foundry-data
    chmod 755 /mnt/foundry-data
  '';

  # Define the Foundry VTT service using Docker
  systemd.services.foundry = {
    description = "Foundry Virtual Tabletop";
    wantedBy = [ "multi-user.target" ];
    after = [ "docker.service" "network.target" ];
    requires = [ "docker.service" ];

    # Prevent service from stopping during deployment
    stopIfChanged = false;

    # Restart during deployment
    restartIfChanged = true;

    serviceConfig = {
      Type = "simple";
      EnvironmentFile = "/etc/foundry/foundry.env";

      ExecStartPre = [
        # Cleanup any existing container
        "-${pkgs.docker}/bin/docker stop foundry"
        "-${pkgs.docker}/bin/docker rm foundry"
        # Pull latest image
        "${pkgs.docker}/bin/docker pull felddy/foundryvtt:release"
      ];

      ExecStart = ''
        ${pkgs.docker}/bin/docker run \
          --name foundry \
          --rm \
          -e FOUNDRY_ADMIN_KEY \
          -e FOUNDRY_LICENSE_KEY \
          -e FOUNDRY_USERNAME \
          -e FOUNDRY_PASSWORD \
          -e FOUNDRY_HOSTNAME=rpg.syscd.live \
          -e FOUNDRY_PROXY_SSL=true \
          -e FOUNDRY_PROXY_PORT=443 \
          -e CONTAINER_CACHE=/data/container_cache \
          -v /mnt/foundry-data:/data \
          -p 30000:30000 \
          felddy/foundryvtt:release
      '';

      ExecStop = "${pkgs.docker}/bin/docker stop foundry";

      Restart = "on-failure";
      RestartSec = "30s";
      StartLimitBurst = "3";
    };

    # Configure unit properties
    unitConfig = {
      StartLimitAction = "none";
      FailureAction = "none";
    };
  };

  # Open firewall for Foundry (if using Tailscale directly)
  networking.firewall.allowedTCPPorts = [ 30000 ];
}
