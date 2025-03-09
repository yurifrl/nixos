# Main NixOS configuration
{ config, pkgs, lib, nixpkgs, inputs, ... }:

{
  imports = [
    ./hardware.nix
    ./modules/ssh.nix
    ./modules/cloudflared.nix
    ./modules/tailscale.nix
    ./modules/gatus
    ./users/root.nix
  ];

  # Digital Ocean image configuration
  virtualisation.digitalOceanImage.compressionMethod = "bzip2";

  # System packages
  environment.systemPackages = [
    inputs.self.packages.${pkgs.system}.cowsay-version
  ];
} 