# Workstation-gpu NixOS configuration (Proxmox VM 103, NVIDIA passthrough).
#
# The gaming sibling of configuration-workstation.nix: same dev-VM base
# (shared modules + workstation modules) plus modules/workstation/desktop.nix
# (Hyprland + Steam + NVIDIA) for the passed-through GPU. Deliberately does NOT
# include cloudflared.nix / herdr-phone.nix: those own box-specific network
# identity (the syscd.space tunnel + the herdr.syscd.space front door) and must
# stay on the headless workstation so the tunnel never half-routes here.
{ config, pkgs, lib, nixpkgs, inputs, ... }:

{
  imports = [
    ./modules/shared/ssh.nix
    ./users/root.nix
    ./users/yuri-workstation.nix
    ./modules/workstation/hardware-proxmox.nix
    ./modules/workstation/desktop.nix
    # Dev-tooling parity with the headless workstation (see header note for
    # the two deliberately-omitted modules).
    ./modules/workstation/docker.nix
    ./modules/workstation/k3s.nix
    ./modules/workstation/nix.nix
    ./modules/workstation/cly.nix
    ./modules/workstation/beads.nix
    ./modules/workstation/packages.nix
    ./modules/workstation/nix-ld.nix
    ./modules/workstation/tailscale.nix
    ./modules/workstation/tailscale-company.nix
    ./modules/workstation/cloud-init.nix
    ./modules/workstation/self-rebuild.nix
    ./modules/workstation/github-ssh.nix
    ./modules/workstation/ssh-agent.nix
    ./modules/workstation/herdr-packages.nix
    ./modules/workstation/omp.nix
    ./modules/workstation/agents.nix
  ];

  # Distinct hostname: tailnet MagicDNS name (workstation-gpu), ws-rebuild
  # flake ref, and cloud-init identity all derive from it.
  networking.hostName = "workstation-gpu";
}
