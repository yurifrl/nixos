{ ... }:
{
  imports = [
    ./docker.nix
    ./k3s.nix
    ./packages.nix
    ./nix-ld.nix
    ./tailscale.nix
    ./apps-proxy.nix
    ./cloud-init.nix
    ./self-rebuild.nix
    ./ssh-agent.nix
    ./agents.nix
  ];
}
