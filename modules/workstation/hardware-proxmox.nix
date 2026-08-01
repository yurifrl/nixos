# Proxmox hardware + qcow2 image build target for the workstation dev VM.
# Replaces the DigitalOcean hardware module (hardware.nix): qemu-guest-agent,
# virtio drivers, serial console, and a Proxmox-importable qcow2 image instead
# of `digitalOceanImage`.
{ config, lib, pkgs, modulesPath, inputs, ... }:

{
  imports = [
    # virtio kernel modules for disk/net/console under QEMU/Proxmox
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  # QEMU guest agent so Proxmox can query/shutdown the VM cleanly.
  services.qemuGuest.enable = true;

  # Seabios/MBR boot with GRUB on the whole disk, plus a serial console.
  boot.loader.grub = {
    enable = true;
    device = "/dev/vda";
  };
  boot.loader.timeout = lib.mkDefault 1;
  boot.growPartition = true;
  boot.kernelParams = [ "console=tty1" "console=ttyS0,115200" ];

  # Root filesystem is the single ext4 partition make-disk-image labels "nixos";
  # autoResize grows it to the Proxmox disk on first boot.
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    autoResize = true;
  };

  # Keep nixpkgs on the box for self-rebuild (`nixos-rebuild switch --flake`).
  environment.etc.nixpkgs.source = inputs.nixpkgs;

  system.stateVersion = "25.05";

  # Proxmox-appropriate qcow2 (bz2-compressed to match the CI upload path).
  # Build with:
  #   nix build .#nixosConfigurations.workstation.config.system.build.proxmoxImage
  system.build.proxmoxImage = import "${modulesPath}/../lib/make-disk-image.nix" {
    inherit config lib pkgs;
    name = "nixos-workstation";
    baseName = "nixos-workstation";
    format = "qcow2";
    partitionTableType = "legacy";
    postVM = "${pkgs.bzip2}/bin/bzip2 $diskImage";
  };
  system.build.image = config.system.build.proxmoxImage;
}
