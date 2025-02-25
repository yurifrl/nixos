{
  # Declare the inputs/dependencies
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    deploy-rs.url = "github:serokell/deploy-rs";
  };

  # Define the system configuration
  outputs = {
    self,
    nixpkgs,
    deploy-rs,
    ...
  } @ inputs: {
    nixosConfigurations = {
      digitalOcean = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs nixpkgs;
        };
        modules = [
          "${nixpkgs}/nixos/modules/virtualisation/digital-ocean-image.nix"
          ./configurations.nix
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

    deploy.nodes = {
      digitalOcean = {
        hostname = "167.172.145.100";
        profiles.system = {
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.digitalOcean;
          sshUser = "root";
          remoteBuild = true;
        };
      };
    };
    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
  };
}
