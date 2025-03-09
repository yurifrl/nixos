#!/usr/bin/env bash

BUILDS=(".#nixosConfigurations.digitalOcean.config.system.build.digitalOceanImage")
CACHE="/nix-cache"
KEY_FILE="/root/.ssh/cache-priv-key.pem"
# Note: The key should be used directly without any prefix
TRUSTED_KEY="$(cat /root/.ssh/cache-pub-key.pem)"


# echo "${BUILDS[@]}" | xargs nix build --system x86_64-linux 

# nix build "${https://github.com/nix-community/cache-nix-action}" \
#    --option trusted-public-keys "cache-key-1:${TRUSTED_KEY}" "${BUILDS[@]}" --system x86_64-linux

# nix build .#nixosConfigurations.digitalOcean.config.system.build.digitalOceanImage \
#     --system x86_64-linux \
#     --store /nix-store \
#     --option trusted-public-keys "${TRUSTED_KEY}"


mapfile -t DERIVATIONS < <(echo "${BUILDS[@]}" | xargs nix path-info --derivation)

mapfile -t DEPENDENCIES < <(echo "${DERIVATIONS[@]}" | xargs nix-store --query --requisites --include-outputs)

echo "${DEPENDENCIES[@]}" | xargs nix store sign --key-file "${KEY_FILE}" --recursive

echo "${DEPENDENCIES[@]}" | xargs nix copy --to "${CACHE}"




# $ echo "${BUILDS[@]}" | xargs nix build
# $ mapfile -t DERIVATIONS < <(echo "${BUILDS[@]}" | xargs nix path-info --derivation)
# $ mapfile -t DEPENDENCIES < <(echo "${DERIVATIONS[@]}" | xargs nix-store --query --requisites --include-outputs)
# $ echo "${DEPENDENCIES[@]}" | xargs nix store sign --key-file "${KEY_FILE}" --recursive
# $ echo "${DEPENDENCIES[@]}" | xargs nix copy --to "${CACHE}"