# Workstation dev-VM NixOS configuration (Proxmox).
# Analogous to configuration-foundry.nix, but does NOT import configuration.nix
# because that pulls in the DigitalOcean hardware module + digitalOceanImage.
# Instead it reuses the shared modules directly on top of a Proxmox image.
{ config, pkgs, lib, nixpkgs, inputs, ... }:

{
  imports = [
    ./modules/shared/ssh.nix
    ./users/root.nix
    ./users/yuri-workstation.nix
    ./modules/workstation
    ./modules/workstation/hardware-proxmox.nix
  ];

  networking.hostName = "workstation";

  # Like a DigitalOcean droplet: allow username + password SSH login, in addition
  # to key-based and Tailscale SSH. The box is only reachable over the LAN and the
  # tailnet, and the root/yuri passwords are strong values provisioned from the
  # 1Password `workstation` item via cloud-init. shared/ssh.nix disables password
  # auth by default, so force it on for this host only.
  services.openssh.settings.PasswordAuthentication = lib.mkForce true;
  services.openssh.settings.PermitRootLogin = lib.mkForce "yes";
}
