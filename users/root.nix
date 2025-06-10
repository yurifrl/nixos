# Root user configuration
{ config, lib, pkgs, ... }:

{
  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAvaTuBhwuQHdjIP1k9YQk9YMqmGiOate19iXe6T4IL/" # Local -> 45.55.248.197
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICPvhdB5G3x/vLkM3wGQC+Ug0xHFCAVqAwCmNqRTFnM8 github-actions-deploy" # Github -> 45.55.248.197
    ];

    # Hashed password for root console access
    # openssl passwd -6 $PASSWORD | pbcopy
    # password is in nixos-digitalocean in 1password
    hashedPassword = "$6$/9pgra2Hke1H9KOs$GN7uc29RAj9gcjOJK7nlbBuLrrQZe6zT27l5bLg9FQIymCj3VaniOP/Brv/dWtR1Y0Fw0m3X8gpllb9RdT.rj/";
  };
} 