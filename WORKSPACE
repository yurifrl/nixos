workspace(name = "nixos_config")

# Register rules_nixpkgs to use Nix packages in Bazel
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "io_tweag_rules_nixpkgs",
    strip_prefix = "rules_nixpkgs-0.9.0",
    urls = ["https://github.com/tweag/rules_nixpkgs/archive/v0.9.0.tar.gz"],
)

load("@io_tweag_rules_nixpkgs//nixpkgs:repositories.bzl", "rules_nixpkgs_dependencies")
rules_nixpkgs_dependencies()

load("@io_tweag_rules_nixpkgs//nixpkgs:nixpkgs.bzl", "nixpkgs_git_repository", "nixpkgs_package")

# Use a specific version of nixpkgs
nixpkgs_git_repository(
    name = "nixpkgs",
    revision = "nixos-23.11",  # Using stable NixOS 23.11 channel
    sha256 = "",  # Will be computed on first build
) 