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
    
    serviceConfig = {
      User = "gatus";
      Group = "gatus";
      ExecStart = "${pkgs.gatus}/bin/gatus";
      Restart = "on-failure";
    };
    
    environment = {
      GATUS_CONFIG_PATH = ./config.yaml;
    };
  };
} 