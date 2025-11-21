# Base NixOS configuration shared between all images
{ config, pkgs, lib, nixpkgs, inputs, ... }:

{
  imports = [
    ./hardware.nix
    ./modules/shared/ssh.nix
    ./modules/shared/tailscale.nix
    ./users/root.nix
  ];

  # Digital Ocean image configuration
  virtualisation.digitalOceanImage.compressionMethod = "bzip2";

  # System packages
  environment.systemPackages = [
    inputs.self.packages.${pkgs.system}.cowsay-version
    # Needed for ansible
    pkgs.python3
  ];
}
