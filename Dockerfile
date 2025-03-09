FROM nixos/nix

RUN echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf
RUN echo "extra-platforms = x86_64-linux" >> /etc/nix/nix.conf
RUN echo "system-features = kvm" >> /etc/nix/nix.conf

# Install QEMU and set up binfmt support
RUN nix-env -iA nixpkgs.qemu nixpkgs.go-task nixpkgs.deploy-rs
RUN nix shell nixpkgs#qemu -c qemu-x86_64 --version

ARG DROPLET_IP

# Set up SSH directory
RUN mkdir -p /root/.ssh
RUN ssh-keyscan -t ed25519 ${DROPLET_IP} >> /root/.ssh/known_hosts
# Generate Nix signing key for binary cache
RUN nix-store --generate-binary-cache-key cache-key-1 /root/.ssh/cache-priv-key.pem /root/.ssh/cache-pub-key.pem && \
    chmod 600 /root/.ssh/cache-priv-key.pem && \
    chmod 644 /root/.ssh/cache-pub-key.pem

WORKDIR /workdir

COPY . .