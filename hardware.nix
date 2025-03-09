# Hardware-specific configuration for DigitalOcean
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ 
    # Import DigitalOcean image configuration
    "${modulesPath}/virtualisation/digital-ocean-image.nix"
  ];

  # Swap configuration
  systemd.tmpfiles.rules = [
    "d /swap 0755 root root -"
  ];
  
  swapDevices = [{
    device = "/swap/swapfile";
    size = 1024 * 2; # 2 GB
  }];

  # Store nixpkgs in /etc/nixpkgs
  environment.etc.nixpkgs.source = nixpkgs;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken.
  system.stateVersion = "25.05";

  # boot.binfmt.emulatedSystems = [ "x86_64-linux" ];
} 