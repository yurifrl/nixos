# Enable the modern `nix` CLI (`nix build`, `nix path-info`, ...) and flakes on
# the dev box. Without this, interactive `nix-command`/`flakes` usage errors out
# with "experimental Nix feature 'nix-command' is disabled". CI/Docker set this
# via nix.conf; the running NixOS system needs it declared here.
{ ... }:
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
