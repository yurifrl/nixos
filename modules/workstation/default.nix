{ ... }:
{
  imports = [
    ./docker.nix
    ./k3s.nix
    ./nix.nix
    ./cly.nix
    ./packages.nix
    ./nix-ld.nix
    ./tailscale.nix
    ./tailscale-company.nix
    ./cloudflared.nix
    ./cloud-init.nix
    ./self-rebuild.nix
    ./github-ssh.nix
    ./ssh-agent.nix
    ./herdr-packages.nix
    ./agents.nix
    ./herdr-phone.nix
  ];
}
