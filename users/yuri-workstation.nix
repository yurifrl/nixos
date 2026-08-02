# Primary interactive dev user for the workstation box.
#
# Deliberately NOT in `wheel` (no sudo). Its power comes from the `docker` group
# (full control of the Docker daemon = effectively root-capable for dev work)
# plus read access to the k3s kubeconfig (k3s.nix writes it 0644). That covers
# "can do all things" for a container/k8s dev box without granting sudo.
{ pkgs, ... }:
{
  programs.fish.enable = true;

  users.users.yuri-workstation = {
    isNormalUser = true;
    description = "Yuri (workstation dev user)";
    extraGroups = [ "docker" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAvaTuBhwuQHdjIP1k9YQk9YMqmGiOate19iXe6T4IL/" # Local (same key as root)
    ];
  };
}
