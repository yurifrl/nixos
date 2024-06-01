{
  description = "NixOS configuration for Raspberry Pi and VirtualBox VM on Intel Mac";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations = {
      rpi = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-installer.nix"
          "${nixpkgs}/nixos/modules/installer/cd-dvd/channel.nix"
          ./common.nix
          ./modules
          ./machines/rpi/definition.nix
          ({ ... }: {
            sdImage.compressImage = false; # If true, will build a .zst compressed image.
          })
        ];  
      };

      vm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ./common.nix
          ./modules
          ./machines/vm/definition.nix
        ];
      };
    };

    packages = {
      aarch64-linux.default = self.nixosConfigurations.rpi.config.system.build.sdImage;
      x86_64-linux = self.nixosConfigurations.vm.config.system.build.isoImage;
    };
    
    colmena = {
      meta = {
        nixpkgs = import nixpkgs {
          system = "x86_64-linux";
          overlays = [];
        };
      };

      defaults = { pkgs, lib, name, nodes, meta, ... }: {
        imports = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"

          ./common.nix
          # ./modules
          ./machines/${name}/definition.nix
        ];

        deployment = {
          buildOnTarget = lib.mkDefault true;
        };
      };
      rpi = {
        deployment = {
          targetHost = "192.168.68.109";
          targetUser = "nixos";
        };
      };
      
      vm = {
        deployment = {
          targetHost = "127.0.0.1";
          targetPort = 2222;
          targetUser = "nixos";
        };
      };
    };
  };
}
