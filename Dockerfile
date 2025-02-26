FROM nixos/nix


# Enable nix features and cross-compilation
RUN echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf
RUN echo "extra-platforms = x86_64-linux" >> /etc/nix/nix.conf
RUN echo "system-features = kvm" >> /etc/nix/nix.conf

# Install QEMU and set up binfmt support
RUN nix-env -iA nixpkgs.go-task

# Create build directory
WORKDIR /workdir

# Copy your flake files
COPY . .

# 
#  nix build .#nixosConfigurations.hal9000.config.system.build.digitalOceanImage