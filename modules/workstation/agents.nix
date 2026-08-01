# pi + herdr — the point of the workstation box.
#
# herdr: a Rust binary, NOT on npm. Pinned prebuilt upstream Linux release,
#        dynamically linked so autoPatchelfHook fixes its interpreter/libs.
# pi:    npm package, updates very frequently -> installed imperatively via bun
#        at boot so it self-updates (not pinned in nixpkgs).
{ pkgs, lib, ... }:
let
  herdr = pkgs.stdenv.mkDerivation {
    pname = "herdr";
    version = "0.7.5";

    src = pkgs.fetchurl {
      url = "https://github.com/herdrdev/herdr/releases/download/v0.7.5/herdr-linux-x86_64";
      hash = "sha256-PcgyiAc+TC08Z5ow576XvMqRQcb9F9u7khkULpXFklM=";
    };

    dontUnpack = true;
    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = [ pkgs.stdenv.cc.cc.lib ];

    installPhase = ''
      runHook preInstall
      install -Dm755 $src $out/bin/herdr
      runHook postInstall
    '';

    meta = with lib; {
      description = "herdr — terminal multiplexer for coding agents";
      homepage = "https://github.com/herdrdev/herdr";
      license = licenses.agpl3Plus;
      mainProgram = "herdr";
      platforms = [ "x86_64-linux" ];
    };
  };
in
{
  environment.systemPackages = [ herdr ];

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
