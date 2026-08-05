# Root user configuration
{ config, lib, pkgs, ... }:

{
  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAvaTuBhwuQHdjIP1k9YQk9YMqmGiOate19iXe6T4IL/" # Local -> 45.55.248.197
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICPvhdB5G3x/vLkM3wGQC+Ug0xHFCAVqAwCmNqRTFnM8 github-actions-deploy" # Github -> 45.55.248.197
    ];

    # No password baked into this (public) repo. The root password is provisioned
    # at boot by cloud-init `chpasswd` from the 1Password `workstation` item
    # (ROOT_PASSWORD), delivered as a $6$ hash via the crossplane workstation
    # cloud-init snippet. With users.mutableUsers = true (default) NixOS leaves an
    # undeclared password alone, so the cloud-init-set password persists across
    # rebuilds. Key-based / Tailscale SSH still works even before cloud-init runs.
  };
} 