# Route git@github.com through the on-box deploy key delivered by the crossplane
# workstation cloud-init render (write_files -> ~/.ssh/id_workstation_deploy).
#
# System-wide client config (/etc/ssh/ssh_config): `~` expands per-user, so this
# one block serves both root (used by ws-rebuild in self-rebuild.nix) and
# yuri-workstation's interactive git. IdentitiesOnly pins this single key so a
# populated/forwarded agent can't exhaust MaxAuthTries and cause intermittent
# "Permission denied (publickey)".
{ ... }:
{
  programs.ssh.extraConfig = ''
    Host github.com
        HostName github.com
        User git
        IdentityFile ~/.ssh/id_workstation_deploy
        IdentitiesOnly yes
  '';
}
