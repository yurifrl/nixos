{ ... }:
{
  imports = [
    ./docker.nix
    ./k3s.nix
    ./packages.nix
    ./tailscale.nix
    ./cloud-init.nix
    ./self-rebuild.nix
    ./agents.nix
  ];
}
