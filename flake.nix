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
  }: {
    nixosConfigurations = {
      digitalOcean = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
        };
        modules = [
          ./configurations.nix
        ];
      };
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
