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

  # herdr remote access: headless herdr server + herdr-phone relay (external
  # front-door mode). The relay serves 127.0.0.1:8787 and validates the
  # Cloudflare Access JWT; the shared syscd.space cloudflared/proxy on this box
  # forwards herdr.syscd.space -> http://127.0.0.1:8787 (via the LAN bridge). The
  # audience is the AUD of the herdr.syscd.space Cloudflare Access app (crossplane
  # `herdr-phone` chart) — a stable id preserved across the domain change from
  # herdr.syscd.live.
  services.herdrPhone.enable = true;
  services.herdrPhone.audience = "511b97a8a412753a39b411f25c79fbd3318805ed1951b1a3c7429067ae407bb6";

  # Like a DigitalOcean droplet: allow username + password SSH login, in addition
  # to key-based and Tailscale SSH. The box is only reachable over the LAN and the
  # tailnet, and the root/yuri passwords are strong values provisioned from the
  # 1Password `workstation` item via cloud-init. shared/ssh.nix disables password
  # auth by default, so force it on for this host only.
  services.openssh.settings.PasswordAuthentication = lib.mkForce true;
  services.openssh.settings.PermitRootLogin = lib.mkForce "yes";
}
