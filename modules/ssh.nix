# SSH service configuration
{ config, lib, pkgs, ... }:

{
  # SSH Configuration
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };
} 