# Main NixOS configuration (backward compatibility - points to Gatus config)
# For new deployments, use configuration-gatus.nix or configuration-foundry.nix directly
{ config, pkgs, lib, nixpkgs, inputs, ... }:

{
  imports = [
    ./configuration-gatus.nix
  ];
} 