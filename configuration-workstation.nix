# Workstation dev-VM NixOS configuration (Proxmox).
# Analogous to configuration-foundry.nix, but does NOT import configuration.nix
# because that pulls in the DigitalOcean hardware module + digitalOceanImage.
# Instead it reuses the shared modules directly on top of a Proxmox image.
{ config, pkgs, lib, nixpkgs, inputs, ... }:

{
  imports = [
    ./modules/shared/ssh.nix
    ./users/root.nix
    ./modules/workstation
    ./modules/workstation/hardware-proxmox.nix
  ];

  networking.hostName = "workstation";
}
