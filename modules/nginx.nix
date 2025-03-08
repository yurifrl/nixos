# Nginx service configuration
{ config, lib, pkgs, ... }:

{
  # ACME/Let's Encrypt configuration
  security.acme = {
    acceptTerms = true;
    defaults.email = "yurifl03@syscd.live";
  };

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
} 