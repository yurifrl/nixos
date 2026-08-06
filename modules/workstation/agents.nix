# pi + herdr — the point of the workstation box.
#
# herdr: pinned prebuilt upstream Linux release, defined once in the overlay
#        (herdr-packages.nix) so herdr-phone.nix shares the same package.
# pi:    npm package, updates very frequently -> installed imperatively via bun
#        at boot so it self-updates (not pinned in nixpkgs).
{ pkgs, lib, ... }:
{
  environment.systemPackages = [ pkgs.herdr ];

  # pi: self-updating global bun install at every boot.
  systemd.services.pi-install = {
    description = "Install/update pi coding agent (bun global)";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.bun pkgs.gitMinimal ];
    environment.BUN_INSTALL = "/var/lib/bun";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StateDirectory = "bun"; # /var/lib/bun, created + owned for the unit
      ExecStart = "${pkgs.bun}/bin/bun install -g @earendil-works/pi-coding-agent";
    };
  };

  # Make the bun global prefix resolvable everywhere: sessionVariables land in
  # the PAM environment, so `pi` resolves for login/interactive shells and for
  # non-interactive `ssh root@box pi`. BUN_INSTALL here also makes ad-hoc
  # `bun install -g` land in the same prefix.
  environment.sessionVariables = {
    BUN_INSTALL = "/var/lib/bun";
    PATH = [ "/var/lib/bun/bin" ];
  };
}
