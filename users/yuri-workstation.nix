# Primary interactive dev user for the workstation box.
#
# In `wheel` (sudo) and `docker`. sudo requires its password (set from the
# `workstation` 1Password item via cloud-init), so this is a real, password-gated
# escalation — not the old locked-password setup where a sudo prompt could never
# be satisfied. Also reads the k3s kubeconfig (k3s.nix writes it 0644).
{ pkgs, ... }:
{
  programs.fish.enable = true;

  users.users.yuri-workstation = {
    isNormalUser = true;
    description = "Yuri (workstation dev user)";
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAvaTuBhwuQHdjIP1k9YQk9YMqmGiOate19iXe6T4IL/" # Local (same key as root)
    ];
  };

  # kubectl works with zero env setup: point ~/.kube/config at the world-readable
  # k3s kubeconfig. Robust across all shells/contexts (env vars don't reach fish
  # reliably on NixOS).
  systemd.tmpfiles.rules = [
    "d /home/yuri-workstation/.kube 0700 yuri-workstation users -"
    "L+ /home/yuri-workstation/.kube/config - - - - /etc/rancher/k3s/k3s.yaml"
  ];
}
