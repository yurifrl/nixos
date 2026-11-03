# Self-rebuild from the nixos repo (design.md §6).
# `ws-rebuild` clones/pulls this repo using the GitHub deploy key that
# workstation-bootstrap.sh op-reads to /root/.ssh/id_workstation_deploy, then
# runs `nixos-rebuild switch --flake .#<hostname>` under sudo.
#
# Agent workflows (and ws-rebuild) run unattended: the 1Password CLI daemon
# keeps expiring, so password prompts stall rebuilds. NOPASSWD is scoped to
# exactly the nixos-rebuild command — every other sudo still requires the
# password.
{
  config,
  pkgs,
  ...
}:
let
  repoUrl = "git@github.com:Yurifrl/nixos.git";
  # RepoDir and hostname-agnostic flake ref: the same image boots the
  # workstation and its workstation-gpu config, and both rebuild themselves.
  repoDir = "/root/nixos";
  # Path matches workstation-bootstrap.sh GH_DEPLOY_KEY_FILE.
  deployKey = "/root/.ssh/id_workstation_deploy";

  ws-rebuild = pkgs.writeShellApplication {
    name = "ws-rebuild";
    runtimeInputs = [
      pkgs.git
      pkgs.openssh
    ];
    text = ''
      export GIT_SSH_COMMAND="ssh -i ${deployKey} -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"
      if [ -d "${repoDir}/.git" ]; then
        git -C "${repoDir}" pull --ff-only
      else
        git clone "${repoUrl}" "${repoDir}"
      fi
      sudo /run/current-system/sw/bin/nixos-rebuild switch --flake "${repoDir}#${config.networking.hostName}"
    '';
  };
in
{
  environment.systemPackages = [ ws-rebuild ];

  security.sudo.extraRules = [
    {
      users = [ "yuri-workstation" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = [
            "NOPASSWD"
            "SETENV"
          ];
        }
        {
          command = "/run/booted-system/sw/bin/nixos-rebuild";
          options = [
            "NOPASSWD"
            "SETENV"
          ];
        }
      ];
    }
  ];
}
