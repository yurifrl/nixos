{
  # Declare the inputs/dependencies
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    deploy-rs.url = "github:serokell/deploy-rs";
  };

  # Define the system configuration
  outputs = { self, nixpkgs, deploy-rs, ... } @ inputs: 
    let
      # need to run deploy path:.#
      config = builtins.fromJSON (builtins.readFile ./deploy.json);
    in {
    packages.x86_64-linux = import ./packages { 
      pkgs = nixpkgs.legacyPackages.x86_64-linux; 
    };

    nixosConfigurations = {
      # Gatus monitoring server configuration
      gatus = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs nixpkgs;
        };
        modules = [
          ./configuration-gatus.nix
          ./hardware.nix
        ];
      };

      # Foundry VTT server configuration
      foundry = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs nixpkgs;
        };
        modules = [
          ./configuration-foundry.nix
          ./hardware.nix
        ];
      };

      # Backward compatibility: digitalOcean points to gatus
      digitalOcean = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs nixpkgs;
        };
        modules = [
          ./configuration.nix
          ./hardware.nix
        ];
      };
    };

    # Separate image configuration for faster switching
    images = {
      digitalOcean = 
        (self.nixosConfigurations.digitalOcean.extendModules {
          modules = [
            {
              virtualisation.digitalOceanImage.compressionMethod = "bzip2";
            }
          ];
        }).config.system.build.digitalOceanImage;
    };
    deploy = {
      nodes = {
        # Gatus monitoring node
        gatus = {
          hostname = config.nodes.gatus.tailscaleHostname or config.digitalOceanTailscaleHostname;
          profiles.system = {
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.gatus;
            sshUser = "root";
            remoteBuild = true;
          };
        };

        # Foundry VTT node
        foundry = {
          hostname = config.nodes.foundry.tailscaleHostname or "";
          profiles.system = {
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.foundry;
            sshUser = "root";
            remoteBuild = true;
          };
        };

        # Backward compatibility
        digitalOcean = {
          hostname = config.digitalOceanTailscaleHostname or config.nodes.gatus.tailscaleHostname;
          profiles.system = {
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.digitalOcean;
            sshUser = "root";
            remoteBuild = true;
          };
        };
      };
    };

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

    devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
      buildInputs = with nixpkgs.legacyPackages.x86_64-linux; [ openssh ];
      shellHook = ''
        echo "Adding ${config.digitalOceanHostname} to known_hosts..."
        ssh-keyscan -t ed25519 ${config.digitalOceanHostname} >> ~/.ssh/known_hosts 2>/dev/null || echo "Could not reach ${config.digitalOceanHostname}"
      '';
    };
  };
}
