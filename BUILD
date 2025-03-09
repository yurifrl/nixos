load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_package")

# Define filegroup for NixOS configuration files
filegroup(
    name = "nixos_config_files",
    srcs = glob([
        "*.nix",
        "modules/**/*.nix",
        "packages/**/*.nix",
        "users/**/*.nix",
    ]),
    visibility = ["//visibility:public"],
)

# Target to evaluate NixOS configuration
sh_test(
    name = "nixos_config_test",
    size = "small",
    srcs = ["nixos_test.sh"],
    data = [":nixos_config_files"],
)

# Generate a shell script to test NixOS configuration
genrule(
    name = "generate_test_script",
    outs = ["nixos_test.sh"],
    cmd = """cat > $@ << 'EOF'
#!/bin/bash
set -euo pipefail

# Test if the NixOS configuration evaluates correctly
nixos-rebuild dry-build --flake .#
EOF
chmod +x $@
""",
) 