# Root user configuration
{ config, lib, pkgs, ... }:

{
  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAvaTuBhwuQHdjIP1k9YQk9YMqmGiOate19iXe6T4IL/" # Local -> 45.55.248.197
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICPvhdB5G3x/vLkM3wGQC+Ug0xHFCAVqAwCmNqRTFnM8 github-actions-deploy" # Github -> 45.55.248.197
    ];

    # Hashed password for root console access
    hashedPassword = "$6$LtO26JQvixkuhF1Z$lEAnQyj.iZwoB2oebUPzOnteGmZPzXgir.Z1aK6B2Gy9WS4BF3grBcI89PJOz/tkdLXUIR9QJXgSw9zDI6wRq.";
  };
} 