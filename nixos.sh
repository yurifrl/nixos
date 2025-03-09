#!/usr/bin/env bash

BUILDS=(".#nixosConfigurations.digitalOcean.config.system.build.digitalOceanImage")
CACHE="/nix-cache"
KEY_FILE="/root/.ssh/cache-priv-key.pem"
# Note: The key is specified without the "cache-key-1:" prefix in the trusted-public-keys option
TRUSTED_KEY="$(cat /root/.ssh/cache-pub-key.pem)"


echo "${BUILDS[@]}" | xargs nix build --system x86_64-linux

# nix build --option substituters "${https://github.com/nix-community/cache-nix-action}" \
#    --option trusted-public-keys "cache-key-1:${TRUSTED_KEY}" "${BUILDS[@]}" --system x86_64-linux

# nix build .#nixosConfigurations.digitalOcean.config.system.build.digitalOceanImage \
#     --system x86_64-linux \
#     --option substituters \
#     --option trusted-public-keys "cache-key-1:${TRUSTED_KEY}"

# echo "${BUILDS[@]}" | xargs nix build

# mapfile -t DERIVATIONS < <(echo "${BUILDS[@]}" | xargs nix path-info --derivation)

# mapfile -t DEPENDENCIES < <(echo "${DERIVATIONS[@]}" | xargs nix-store --query --requisites --include-outputs)

# echo "${DEPENDENCIES[@]}" | xargs nix store sign --key-file "${KEY_FILE}" --recursive

# # Note: The "cache-key-1:" prefix is added here in the trusted-public-keys option
# echo "${DEPENDENCIES[@]}" | xargs nix copy --to "${CACHE}" --option trusted-public-keys "cache-key-1:${TRUSTED_KEY}"