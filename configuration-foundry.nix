# Foundry VTT-specific NixOS configuration
{ config, pkgs, lib, nixpkgs, inputs, ... }:

{
  imports = [
    ./configuration.nix
    ./modules/foundry
    ./modules/foundry/cloudflared.nix
  ];

  # DigitalOcean Block Storage Volume Configuration
  # This assumes the volume is attached at /dev/disk/by-id/scsi-0DO_Volume_foundry-data
  # and should be mounted at /mnt/foundry-data
  fileSystems."/mnt/foundry-data" = {
    device = "/dev/disk/by-id/scsi-0DO_Volume_foundry-data";
    fsType = "ext4";
    options = [ "defaults" "nofail" ];
  };

  # Foundry-specific system settings
  # Increase swap since Foundry can be memory-intensive
  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 4096; # 4GB swap
    }
  ];
}
