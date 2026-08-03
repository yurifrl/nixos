# Keep SSH agent forwarding usable across persistent (herdr) reconnects.
#
# Agent forwarding is per-connection: the forwarded socket dies when the SSH
# connection that created it closes, so a reattached herdr pane ends up with a
# dead $SSH_AUTH_SOCK. Tailscale SSH also bypasses /etc/ssh/sshrc, so we can't
# hook there. Instead, stabilize the socket in interactive shell init:
#   1. If we arrive with a real forwarded socket, (re)point a fixed symlink
#      (~/.ssh/agent.sock) at it.
#   2. Always resolve SSH_AUTH_SOCK through that symlink.
# Panes opened before a reconnect keep the same fixed path, which now points at
# the fresh socket — so git/ssh work again after opening one new pane, with no
# keys ever stored on the box.
{ ... }:
let
  fishInit = ''
    if set -q SSH_AUTH_SOCK; and test "$SSH_AUTH_SOCK" != "$HOME/.ssh/agent.sock"; and test -S "$SSH_AUTH_SOCK"
        mkdir -p "$HOME/.ssh"
        ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/agent.sock"
    end
    if test -S "$HOME/.ssh/agent.sock"
        set -gx SSH_AUTH_SOCK "$HOME/.ssh/agent.sock"
    end
  '';
  bashInit = ''
    if [ -n "$SSH_AUTH_SOCK" ] && [ "$SSH_AUTH_SOCK" != "$HOME/.ssh/agent.sock" ] && [ -S "$SSH_AUTH_SOCK" ]; then
      mkdir -p "$HOME/.ssh"
      ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/agent.sock"
    fi
    if [ -S "$HOME/.ssh/agent.sock" ]; then
      export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
    fi
  '';
in
{
  programs.fish.interactiveShellInit = fishInit;
  programs.bash.interactiveShellInit = bashInit;
}
