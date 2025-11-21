# Gatus-specific NixOS configuration
{ config, pkgs, lib, nixpkgs, inputs, ... }:

{
  imports = [
    ./configuration.nix
    ./modules/gatus
    ./modules/gatus/cloudflared.nix
  ];

  # Gatus-specific system settings can go here if needed
}
