# Digital Ocean NixOS configuration
{ config, pkgs, lib, nixpkgs, ... }: {
  # Digital Ocean image configuration
  virtualisation.digitalOceanImage.compressionMethod = "bzip2";

  # ACME/Let's Encrypt configuration
  security.acme = {
    acceptTerms = true;
    defaults.email = "yurifl03@syscd.live";  # Replace with your email
  };

  # SSH Configuration
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
  };

  # Root user configuration 
  users.users.root = {
    openssh.authorizedKeys.keys = [
      # Replace with your SSH public key
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAvaTuBhwuQHdjIP1k9YQk9YMqmGiOate19iXe6T4IL/"
    ];
    # Optional: Add a hashed password for root console access
    hashedPassword = "$6$LtO26JQvixkuhF1Z$lEAnQyj.iZwoB2oebUPzOnteGmZPzXgir.Z1aK6B2Gy9WS4BF3grBcI89PJOz/tkdLXUIR9QJXgSw9zDI6wRq.";
  };

  # Swap configuration
  swapDevices = [{
    device = "/swap/swapfile";
    size = 1024 * 2; # 2 GB
  }];

  # Nginx configuration
  services.nginx = {
    enable = true;
    virtualHosts."hal9000.example" = {
      enableACME = true;
      forceSSL = true;
      root = pkgs.runCommand "www-dir" { } ''
        mkdir -p $out
        cat > $out/index.html <<EOF
          <!DOCTYPE html>
          <html lang="en">
          <body>
            <h1>
                I'm sorry Dave, I'm afraid this
                pop culture reference is overused.
            <h1>
          </body>
          </html>
        EOF
      '';
    };
  };

  # Store nixpkgs in /etc/nixpkgs
  environment.etc.nixpkgs.source = nixpkgs;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  system.stateVersion = "25.05";
} 