#!/usr/bin/env bash
#
# https://www.haskellforall.com/2022/10/how-to-correctly-cache-build-time.html
#

BUILDS=(".#nixosConfigurations.digitalOcean.config.system.build.digitalOceanImage")

mapfile -t DERIVATIONS < <(echo "${BUILDS[@]}" | xargs nix path-info --derivation)
echo "${DERIVATIONS}"

mapfile -t DEPENDENCIES < <(echo "${DERIVATIONS[@]}" | xargs nix-store --query --requisites --include-outputs)
echo "${DEPENDENCIES}"

echo "${DEPENDENCIES[@]}" | xargs nix store sign --key-file "${KEY_FILE}" --recursive
echo "${DEPENDENCIES[@]}" | xargs nix copy --to "${NIX_CACHE}"