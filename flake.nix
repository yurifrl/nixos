{
  # Declare the inputs/dependencies
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Sunshine v2026.914.233613 (GHSA-fp6g-27w5-489j high-severity Linux fix):
    # the host's pinned nixpkgs still ships 2025.924, so the stream host is
    # built from this dedicated pin (sunshine bumped @ 67d12d232 + darwin fix).
    nixpkgs-sunshine.url = "github:NixOS/nixpkgs/be341b76699a77bb258a3c2ec8ad11e095810e83";
    # Lutris 0.5.22 (the host's pinned nixpkgs ships 0.5.19; Lutris itself
    # demands >= 0.5.22 for the Battle.net installer flows).
    nixpkgs-lutris.url = "github:NixOS/nixpkgs/d06395a79178570d94367940dd239b9af91c9838";
    deploy-rs.url = "github:serokell/deploy-rs";
    cly.url = "github:yurifrl/cly";
    # (go.mod requires >= 1.25.8). Letting it use its own nixos-unstable pin means
    # it always builds with the latest Go, instead of this host's pinned nixpkgs.
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

      # Workstation dev VM (Proxmox). Brings its own Proxmox hardware/image
      # module, so ./hardware.nix (DigitalOcean) is intentionally omitted.
      # qcow2 build target:
      #   nix build .#nixosConfigurations.workstation.config.system.build.proxmoxImage
      workstation = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs nixpkgs;
        };
        modules = [
          ./configuration-workstation.nix
        ];
      };
    };

    deploy = {
      nodes = {
        # Gatus monitoring node
        gatus = {
          hostname = config.nodes.gatus.tailscaleHostname;
          profiles.system = {
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.gatus;
            sshUser = "root";
            remoteBuild = true;
          };
        };

        # Foundry VTT node (rpg)
        foundry = {
          hostname = config.nodes.foundry.tailscaleHostname;
          profiles.system = {
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.foundry;
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
        echo "Adding nodes to known_hosts..."
        ssh-keyscan -t ed25519 ${config.nodes.gatus.tailscaleHostname} >> ~/.ssh/known_hosts 2>/dev/null || echo "Could not reach gatus"
        ssh-keyscan -t ed25519 ${config.nodes.foundry.tailscaleHostname} >> ~/.ssh/known_hosts 2>/dev/null || echo "Could not reach rpg"
      '';
    };
  };
}
