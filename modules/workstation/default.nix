{ ... }:
{
  imports = [
    ./docker.nix
    ./k3s.nix
    ./packages.nix
    ./nix-ld.nix
    ./tailscale.nix
    ./cloudflared.nix
    ./cloud-init.nix
    ./self-rebuild.nix
    ./ssh-agent.nix
    ./herdr-packages.nix
    ./agents.nix
    ./herdr-phone.nix
  ];
}
