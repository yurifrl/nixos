FROM nixos/nix

RUN echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf
RUN echo "extra-platforms = x86_64-linux" >> /etc/nix/nix.conf
RUN echo "system-features = kvm" >> /etc/nix/nix.conf

# Install QEMU and set up binfmt support
RUN nix-env -iA nixpkgs.qemu nixpkgs.go-task nixpkgs.deploy-rs
RUN nix shell nixpkgs#qemu -c qemu-x86_64 --version

ARG DROPLET_IP

RUN mkdir ~/.ssh
RUN ssh-keyscan -t ed25519 ${DROPLET_IP} >> ~/.ssh/known_hosts

WORKDIR /workdir

COPY . .