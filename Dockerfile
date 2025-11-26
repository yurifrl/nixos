FROM nixos/nix

RUN echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf
RUN echo "extra-platforms = x86_64-linux" >> /etc/nix/nix.conf

# Install QEMU, task, deploy-rs, and Bazel with dependencies
RUN nix-env -iA \
    nixpkgs.go-task \
    nixpkgs.deploy-rs

# === Bazel
RUN nix-env -iA \
nixpkgs.bazel_6 \
nixpkgs.gcc \
nixpkgs.python3
# Verify Bazel installation
RUN bazel --version
# Create Bazel cache directory and set permissions
RUN mkdir -p /root/.cache/bazel && \
    chmod -R 777 /root/.cache/bazel

# === Cache
# Create SSH directory and generate Nix signing key for binary cache
RUN mkdir -p /root/.ssh && \
    nix-store --generate-binary-cache-key cache-key-1 /root/.ssh/cache-priv-key.pem /root/.ssh/cache-pub-key.pem && \
    chmod 600 /root/.ssh/cache-priv-key.pem && \
    chmod 644 /root/.ssh/cache-pub-key.pem

ENV NIX_CACHE="file:///nix-cache"
ENV NIX_KEY_FILE="/root/.ssh/cache-priv-key.pem"
ENV NIX_CACHE="/nix-cache"

RUN echo "system-features = kvm" >> /etc/nix/nix.conf
RUN echo "extra-substituters = ${NIX_CACHE}" >> /etc/nix/nix.conf
RUN echo "extra-trusted-public-keys = $(cat /root/.ssh/cache-pub-key.pem)" >> /etc/nix/nix.conf

WORKDIR /workdir

VOLUME /nix-cache

COPY . .