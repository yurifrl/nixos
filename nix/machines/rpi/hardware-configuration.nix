{ config, lib, pkgs, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "virtio_pci" "xhci_pci" "usb_storage" "usbhid" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.eth0.useDHCP = lib.mkDefault true;
  # networking.interfaces.tailscale0.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlan0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  systemd.repart.partitions = {
    "00-esp" = {
      Type = "esp";
      SizeMaxBytes = "1G";
      Format = "vfat";
    };
    "10-root" = {
      Type = "root-arm64";
      Format = "btrfs"; # or "ext4" depending on your preference
    };
  };

  fileSystems."/" =
    let
      root = config.systemd.repart.partitions."10-root";
    in
    {
      device = "/dev/disk/by-partlabel/${root.Type}";
      fsType = lib.mkForce root.Format; # Ensures correct fsType without conflicts
    };

  fileSystems."/mnt" = {
    device = "share";
    fsType = "virtiofs";
  };

  systemd.network.networks.main = {
    matchConfig.Name = "en*";
    networkConfig = {
      DHCP = "yes";
      MulticastDNS = "yes";
    };
  };

  # Other configurations...
}
