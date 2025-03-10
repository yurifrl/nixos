{ config, pkgs, ... }:
{
  # Fixed user/group
  users.users.gatus = {
    isSystemUser = true;
    group = "gatus";
    description = "Gatus service user";
  };
  
  users.groups.gatus = {};
  
  # Ensure the package is installed
  environment.systemPackages = [ pkgs.gatus ];
  
  # Define the Gatus service
  systemd.services.gatus = {
    description = "Gatus";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    
    # Prevent service from stopping during deployment
    stopIfChanged = false;
    
    # Don't restart during deployment
    restartIfChanged = false;
    
    serviceConfig = {
      User = "gatus";
      Group = "gatus";
      ExecStart = "${pkgs.gatus}/bin/gatus";
      Restart = "on-failure";
      # More aggressive restart settings
      RestartSec = "10s";
      # No limit on restart attempts
      StartLimitBurst = "0";
      # Required environment variables
      # CF_ACCESS_CLIENT_ID, CF_ACCESS_CLIENT_SECRET, DISCORD_WEBHOOK_URL
      EnvironmentFile = "/etc/gatus/gatus.env";
    };
    
    # Configure unit properties to prevent failed service from affecting deployment
    unitConfig = {
      # Do nothing when service fails to start repeatedly
      StartLimitAction = "none";
      # Do nothing when service fails
      FailureAction = "none";
    };
    
    environment = {
      GATUS_CONFIG_PATH = ./config.yaml;
    };
  };
} 