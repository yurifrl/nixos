# cly: personal dev CLI, packaged as a flake (github:yurifrl/cly). Consumed via
# its overlay so `pkgs.cly` is available to packages.nix, replacing the old
# curl-based `install.sh` download (which only shipped darwin binaries).
{ inputs, ... }:
{
  nixpkgs.overlays = [ inputs.cly.overlays.default ];
}
