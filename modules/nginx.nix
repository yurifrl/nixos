# Nginx service configuration
{ config, lib, pkgs, ... }:

{
  services.nginx = {
    enable = true;
    # Listen only on localhost since Cloudflared will proxy the requests
    defaultListenAddresses = [ "127.0.0.1" ];
    virtualHosts."hal9000.example" = {
      # Force HTTPS since Cloudflare will handle SSL termination
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