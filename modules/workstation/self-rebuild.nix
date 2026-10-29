# Self-rebuild from the nixos repo (design.md §6).
# `ws-rebuild` clones/pulls this repo using the GitHub deploy key that
# workstation-bootstrap.sh op-reads to /root/.ssh/id_workstation_deploy, then
# runs `nixos-rebuild switch --flake .#workstation`.
{ pkgs, ... }:
let
  repoUrl = "git@github.com:Yurifrl/nixos.git";
  repoDir = "/root/nixos";
  # Path matches workstation-bootstrap.sh GH_DEPLOY_KEY_FILE.
  deployKey = "/root/.ssh/id_workstation_deploy";

  ws-rebuild = pkgs.writeShellApplication {
    name = "ws-rebuild";
    runtimeInputs = [ pkgs.git pkgs.openssh pkgs.nixos-rebuild ];
    text = ''
      export GIT_SSH_COMMAND="ssh -i ${deployKey} -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"
      if [ -d "${repoDir}/.git" ]; then
        git -C "${repoDir}" pull --ff-only
      else
        git clone "${repoUrl}" "${repoDir}"
      fi
      nixos-rebuild switch --flake "${repoDir}#workstation"
    '';
  };
in
{
  environment.systemPackages = [ ws-rebuild ];
}
