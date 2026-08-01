{ ... }:
{
  imports = [
    ./docker.nix
    ./k3s.nix
    ./packages.nix
    ./tailscale.nix
    ./self-rebuild.nix
    ./agents.nix
  ];
}
