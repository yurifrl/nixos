# Digital Ocean NixOS configuration
{ config, pkgs, lib, nixpkgs, inputs, ... }:

let
  myPkgs = inputs.self.packages.${pkgs.system};
in
{
  imports = [
    # Import hardware configuration
    ./hardware.nix
    # Import our modules
    ../../modules/nginx.nix
    ../../modules/ssh.nix
    ../../users/root.nix
  ];

  # Digital Ocean image configuration
  virtualisation.digitalOceanImage.compressionMethod = "bzip2";

  # System packages
  environment.systemPackages = [
    # Include our custom cowsay-version package
    myPkgs.cowsay-version
  ];

  # Swap configuration
  swapDevices = [{
    device = "/swap/swapfile";
    size = 1024 * 2; # 2 GB
  }];

  # Store nixpkgs in /etc/nixpkgs
  environment.etc.nixpkgs.source = nixpkgs;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken.
  system.stateVersion = "25.05";
} 