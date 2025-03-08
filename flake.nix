{
  # Declare the inputs/dependencies
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    deploy-rs.url = "github:serokell/deploy-rs";
  };

  # Define the system configuration
  outputs = { self, nixpkgs, deploy-rs, ... } @ inputs: {
    packages.x86_64-linux = import ./packages { 
      pkgs = nixpkgs.legacyPackages.x86_64-linux; 
    };

    nixosConfigurations = {
      digitalOcean = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs nixpkgs;
        };
        modules = [
          ./configuration.nix
          # {
          #   nixpkgs.crossSystem = {
          #     config = "x86_64-unknown-linux-gnu";
          #     system = "x86_64-linux";
          #   };
          # }
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
        digitalOcean = {
          hostname = builtins.getEnv "DROPLET_IP";
          profiles.system = {
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.digitalOcean;
            sshUser = "root";
            remoteBuild = true;
          };
        };
      };
    };

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
  };
}
