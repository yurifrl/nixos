# Second Tailscale daemon for the company tailnet, alongside the personal one.
#
# Why userspace networking: two kernel-mode tailscaleds fight over the tun
# interface and routing. The personal daemon (tailscale.nix) owns tailscale0 +
# Tailscale SSH; this one runs with --tun=userspace-networking, so it makes NO
# network interface and NO Tailscale SSH — it only proxies.
#
# How it's reached: `tailscale serve` on this daemon forwards tailnet TCP/22 to
# the box's openssh (127.0.0.1:22). So from the company tailnet you
# `ssh yuri-workstation@workstation.<company-tailnet>.ts.net`, the daemon
# terminates it, and hands the bytes to sshd. Auth is ordinary sshd auth
# (password / agent), NOT Tailscale SSH, so no company ACL/SSH policy is needed
# beyond "can reach this node".
#
# The auth key is delivered by cloud-init to /etc/tailscale/authkey-company
# (rendered in-cluster from the 1Password item's TAILSCALE_AUTH_KEY_2 field; see
# home-systems workstation-cloud-init-render). The key is reusable + preauthorized.
#
# Nothing company-identifying lives here: no login-server URL (defaults to
# login.tailscale.com), no company tags. The hostname on the company tailnet is
# just this box's networking.hostName ("workstation").
{ pkgs, config, lib, ... }:
let
  stateDir = "/var/lib/tailscale-company";
  runtimeDir = "/run/tailscale-company";
  socket = "${runtimeDir}/tailscaled.sock";
  authKeyFile = "/etc/tailscale/authkey-company";
  port = 0; # userspace daemon doesn't need a UDP listen port
in
{
  # Daemon, mirroring the upstream tailscaled.service invocation but with its own
  # socket/state dir and userspace tun so it never touches tailscale0.
  systemd.services.tailscaled-company = {
    description = "Tailscale node agent (company tailnet, userspace)";
    documentation = [ "https://tailscale.com/kb/" ];
    wants = [ "network-pre.target" ];
    after = [ "network-pre.target" ];
    wantedBy = [ "multi-user.target" ];
    # Same runtime deps the nixpkgs module gives the personal daemon.
    path = [
      pkgs.procps
      pkgs.getent
      pkgs.kmod
    ];
    serviceConfig = {
      Type = "notify";
      Restart = "on-failure";
      RuntimeDirectory = "tailscale-company";
      RuntimeDirectoryMode = "0755";
      StateDirectory = "tailscale-company";
      StateDirectoryMode = "0700";
      CacheDirectory = "tailscale-company";
      CacheDirectoryMode = "0750";
      ExecStart = ''
        ${pkgs.tailscale}/bin/tailscaled \
          --state=${stateDir}/tailscaled.state \
          --socket=${socket} \
          --port=${toString port} \
          --tun=userspace-networking
      '';
      ExecStopPost = "${pkgs.tailscale}/bin/tailscaled --socket=${socket} --cleanup";
    };
  };

  # Autoconnect, mirroring nixpkgs' tailscaled-autoconnect: loop on BackendState,
  # feed the auth key on NeedsLogin, then expose sshd over the company tailnet.
  systemd.services.tailscaled-company-autoconnect = {
    description = "Automatic connection to Tailscale (company tailnet)";
    after = [ "tailscaled-company.service" "cloud-final.service" ];
    wants = [ "tailscaled-company.service" "cloud-final.service" ];
    wantedBy = [ "multi-user.target" ];
    # cloud-init writes the company key; without it this unit has nothing to do.
    unitConfig.ConditionPathExists = authKeyFile;
    serviceConfig.Type = "notify";
    path = [ pkgs.tailscale pkgs.jq ];
    script = ''
      TS="${pkgs.tailscale}/bin/tailscale --socket=${socket}"

      getState() {
        $TS status --json --peers=false | ${pkgs.jq}/bin/jq -r '.BackendState'
      }

      lastState=""
      while state="$(getState)"; do
        if [[ "$state" != "$lastState" ]]; then
          case "$state" in
            NeedsLogin|NeedsMachineAuth|Stopped)
              echo "Company tailnet needs authentication, sending auth key"
              $TS up \
                --auth-key "$(cat ${authKeyFile})" \
                --hostname=${config.networking.hostName} \
                --accept-dns=false \
                --reset
              ;;
            Running)
              echo "Company tailnet is running; exposing sshd on tailnet :22"
              $TS serve --bg --tcp=22 tcp://127.0.0.1:22
              systemd-notify --ready
              exit 0
              ;;
            *)
              echo "Waiting for company tailnet State = Running or systemd timeout"
              ;;
          esac
          echo "State = $state"
        fi
        lastState="$state"
        sleep .5
      done
    '';
  };
}
