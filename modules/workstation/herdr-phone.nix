# herdr remote access, declarative.
#
# Two systemd services running as yuri-workstation:
#
#   herdr-server  the headless herdr server (`herdr server`). It owns the
#                 persistent sessions/panes and the API socket at
#                 ~/.config/herdr/herdr.sock. `herdr --remote` and herdr-phone
#                 both attach to it.
#
#   herdr-phone   the remote-access relay + PWA, run in the fork's `external`
#                 front-door mode: it serves its origin on 127.0.0.1:<port> and
#                 re-validates the Cloudflare Access JWT, but starts NO
#                 cloudflared of its own. The shared syscd.space cloudflared/proxy
#                 that runs on this box forwards
#                     herdr.syscd.space -> http://127.0.0.1:<port>
#                 (per-app port map), passing the Access JWT through to the origin.
#
# The relay stays inactive until the Cloudflare Access AUD for herdr.syscd.space
# is provided (services.herdrPhone.audience). That AUD is the one value shared
# with the syscd.space edge; everything else here is self-contained.
{ config, lib, pkgs, ... }:
let
  cfg = config.services.herdrPhone;
  user = "yuri-workstation";
  home = "/home/${user}";
  herdrConfigDir = "${home}/.config/herdr";
  socket = "${herdrConfigDir}/herdr.sock";
  stateDir = "/var/lib/herdr-phone";

  identitiesToml = lib.concatMapStringsSep ", " (e: "\"${e}\"") cfg.allowedIdentities;

  phoneConfig = pkgs.writeText "herdr-phone-config.toml" ''
    [server]
    host = "127.0.0.1"
    port = ${toString cfg.port}
    allowed_workspace_roots = ["~"]

    [cloudflare]
    mode = "external"
    public_url = "${cfg.publicUrl}"

    [auth.access]
    enabled = true
    team_domain = "${cfg.teamDomain}"
    audience = "${cfg.audience}"
    allowed_identities = [${identitiesToml}]

    [herdr]
    binary = "${pkgs.herdr}/bin/herdr"
    socket_path = "${socket}"
  '';

  # herdr-phone reads $HERDR_PLUGIN_CONFIG_DIR/config.toml first (SPEC precedence).
  phoneConfigDir = pkgs.runCommand "herdr-phone-config" { } ''
    mkdir -p "$out"
    cp ${phoneConfig} "$out/config.toml"
  '';
in
{
  options.services.herdrPhone = {
    enable = lib.mkEnableOption "herdr headless server + herdr-phone remote-access relay";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8787;
      description = "Loopback port the herdr-phone origin binds (the LAN bridge forwards here).";
    };

    lanPort = lib.mkOption {
      type = lib.types.port;
      default = 8788;
      description = ''
        LAN port the herdr-phone origin is bridged onto for the in-cluster
        apps-space cloudflared proxy (which reaches this box over the LAN at
        192.168.68.118:<lanPort>). Must match the herdr entry in the apps map in
        home-systems-values/apps-space/values.yaml.
      '';
    };

    publicUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://herdr.syscd.space";
      description = "Public https URL the shared syscd.space proxy serves for herdr.";
    };

    teamDomain = lib.mkOption {
      type = lib.types.str;
      default = "syscd.cloudflareaccess.com";
      description = "Cloudflare Access team (auth) domain. Account-wide, not a secret.";
    };

    audience = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Cloudflare Access application AUD for herdr.syscd.space (the shared
        syscd.space edge). Not a secret. herdr-phone stays inactive while empty;
        set it and rebuild to bring the relay up.
      '';
    };

    allowedIdentities = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "yurifl03@gmail.com" "yuri.lima@nsx.bet" ];
      description = "Exact-match Access identity allowlist the origin enforces.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Headless herdr server: the substrate herdr-phone and `herdr --remote` attach to.
    systemd.services.herdr-server = {
      description = "herdr headless server (${user})";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      path = [ pkgs.herdr pkgs.git pkgs.openssh pkgs.bash ];
      environment = {
        HOME = home;
        XDG_CONFIG_HOME = "${home}/.config";
      };
      serviceConfig = {
        User = user;
        Group = "users";
        WorkingDirectory = home;
        ExecStart = "${pkgs.herdr}/bin/herdr server";
        Restart = "on-failure";
        RestartSec = "3s";
      };
    };

    # The relay. Only defined once the Access AUD is set, so a fresh box does not
    # run it against an unusable front door (external mode requires a real AUD).
    systemd.services.herdr-phone = lib.mkIf (cfg.audience != "") {
      description = "herdr-phone remote-access relay (external mode)";
      wantedBy = [ "multi-user.target" ];
      after = [ "herdr-server.service" "network-online.target" ];
      wants = [ "network-online.target" ];
      requires = [ "herdr-server.service" ];
      path = [ pkgs.herdr pkgs.bash ];
      environment = {
        HOME = home;
        XDG_CONFIG_HOME = "${home}/.config";
        HERDR_PLUGIN_CONFIG_DIR = phoneConfigDir;
        HERDR_PLUGIN_STATE_DIR = stateDir;
        HERDR_SOCKET_PATH = socket;
        HERDR_BIN_PATH = "${pkgs.herdr}/bin/herdr";
      };
      serviceConfig = {
        User = user;
        Group = "users";
        WorkingDirectory = home;
        StateDirectory = "herdr-phone";
        ExecStart = "${pkgs.herdr-phone}/bin/herdr-phone serve";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    # LAN bridge. herdr-phone binds loopback only (a hard security invariant of
    # the relay), but the in-cluster apps-space cloudflared reaches this box over
    # the LAN. Expose the loopback origin on the LAN via a plain TCP proxy
    # (systemd-socket-proxyd, which passes WebSockets and the Access JWT header
    # through untouched). A direct LAN hit is safe: external mode rejects every
    # request without a valid Cloudflare Access JWT.
    systemd.sockets.herdr-phone-lan = lib.mkIf (cfg.audience != "") {
      description = "herdr-phone LAN bridge socket";
      wantedBy = [ "sockets.target" ];
      socketConfig.ListenStream = toString cfg.lanPort;
    };

    systemd.services.herdr-phone-lan = lib.mkIf (cfg.audience != "") {
      description = "herdr-phone LAN bridge (LAN:${toString cfg.lanPort} -> 127.0.0.1:${toString cfg.port})";
      requires = [ "herdr-phone.service" "herdr-phone-lan.socket" ];
      after = [ "herdr-phone.service" "herdr-phone-lan.socket" ];
      serviceConfig = {
        ExecStart = "${config.systemd.package}/lib/systemd/systemd-socket-proxyd 127.0.0.1:${toString cfg.port}";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    # Open the bridge port on the LAN interface for the in-cluster proxy. tailscale.nix
    # trusts only tailscale0; the origin's Access-JWT check is what makes LAN exposure safe.
    networking.firewall.allowedTCPPorts = lib.mkIf (cfg.audience != "") [ cfg.lanPort ];
  };
}
