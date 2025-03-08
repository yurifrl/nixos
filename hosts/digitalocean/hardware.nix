# Hardware-specific configuration for DigitalOcean
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ 
    # Import DigitalOcean image configuration
    "${modulesPath}/virtualisation/digital-ocean-image.nix"
  ];

  # Add any DigitalOcean-specific hardware configurations here
  boot.loader.grub.device = "/dev/vda";
  fileSystems."/" = {
    device = "/dev/vda1";
    fsType = "ext4";
  };
} 