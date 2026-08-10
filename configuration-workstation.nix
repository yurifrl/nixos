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
  # Cloudflare Access JWT; the on-box syscd-apps cloudflared forwards
  # herdr.syscd.space -> http://127.0.0.1:8787. The audience is the AUD of the
  # dedicated herdr.syscd.space Cloudflare Access app (cloudflare-access chart,
  # application `herdr`), which overrides the *.syscd.space wildcard for this
  # host and gives herdr-phone a stable AUD of its own.
  services.herdrPhone.enable = true;
  services.herdrPhone.audience = "6e763fdf5f78fa75926de0507d736edd0f27ebe560aac24b66b6ce198843e8ef";

  # Like a DigitalOcean droplet: allow username + password SSH login, in addition
  # to key-based and Tailscale SSH. The box is only reachable over the LAN and the
  # tailnet, and the root/yuri passwords are strong values provisioned from the
  # 1Password `workstation` item via cloud-init. shared/ssh.nix disables password
  # auth by default, so force it on for this host only.
  services.openssh.settings.PasswordAuthentication = lib.mkForce true;
  services.openssh.settings.PermitRootLogin = lib.mkForce "yes";
}
