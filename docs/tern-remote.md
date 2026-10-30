# Tern remote access to the workstation

How `tern remote` panes reach the workstation VM (Proxmox VM 102, `pc01`),
what breaks them, and how the pieces fit. Written 2026-10-30 after a long
debugging session — read this before touching tern-remote again.

## The stack

```
Tern.app (Mac, GUI)
  └─ tern daemon (Mac, ~/.config/systemd/user/tern-daemon... via daemon.sock)
       └─ every local pane is a child of the daemon (omp --restore, fish -l)
  └─ remote panes ── QUIC/iroh or SSH tunnel ──> workstation serve
workstation:
  tern remote serve --user (per USER, one each)
    └─ tern daemon (child) ── spawns each pane's fish/omp
```

- Two serves coexist on the box, **one per user, and they fight for UDP 8376**:
  - `yuri-workstation`: systemd user unit `tern-remote`, port **8376**,
    state dir `~yuri-workstation/.config/tern`. This is the daily-driver
    entry (`yuri-workstation@workstation`).
  - `root`: same unit name under `/root/.config/systemd/user/`, state dir
    `/root/.config/tern`. The app's `root@…` setup flow re-enables it and
    **rewrites its unit file**, which is how it historically stole 8376 and
    broke every yuri pane ("host key is not the pinned one").
  - Root's unit is hand-edited with `--listen [::]:8377` to coexist. If the
    app reinstalls it (any new root remote pane through the dialog), re-add
    the flag. Endpoint-id dials ignore the port, so `root@<endpoint id>`
    keeps working either way; only direct `host:8377` dials need it.

## Identities and pins

- Each serve has a stable QUIC identity (key + iroh endpoint id) persisted in
  its state dir across restarts and reboots. It is NOT the `host_cert.der`
  key. It is logged at every serve start:
  `listening on [::]:8376, host key SHA256:…, endpoint id …`.
- Current identities (2026-10-30):
  - yuri-workstation: key `SHA256:NH0VGKcNVYdLnOkEaQU+LuS48vZppP6qLAHG29nOpPw`,
    endpoint `2e3c473fd7e276e21df22d9ccedd359e096bd3160ba6558d400672ca6765682a`
  - root: key `SHA256:VjAIT4GcsYVpNzPoJ26zLwBR4rZRsVTPe7FaAt1Bo5U`, endpoint
    `d0c2a67228c101d534dd9be58eca6252d9bf3f8fe56589236e738bb64b6e3f6c`
- The Mac pins them in `~/Library/Application Support/Tern/known_hosts`
  (per spec: `host:8376` and `<endpoint id>` lines) and lists saved hosts in
  `…/Tern/hosts`. A pin/serve mismatch = Tern refuses with
  "the host's key changed …". Fix by matching serve and spec, not by blindly
  trusting: `tern remote trust <spec> SHA256:…` or fix the pin file.

## Debugging playbook

- Server-side, everything is in the user journal:
  `ssh yuri-workstation@<box> journalctl --user -u tern-remote -f`
  Logins, handshakes, endpoint announcement all land there.
- Client-side: `~/Library/Logs/Tern/tern.log` (app) and `tern-daemon.log`
  (daemon). Look for `tern-remote-<host> … stalled/lost/reconnected` and
  `remote setup step=…` (a setup re-run means a link died).
- `tern remote doctor [user@]host` — checks SSH keys, UDP QUIC reachability,
  relay/pkarr publication, pin match, auth. Green doctor + broken pane =
  client rendering issue, not transport.
- A new pane that comes up broken after a link flap stays broken: the pane's
  initial shell-integration sequences are lost mid-connect. Close and
  recreate it; don't debug the healthy serve.
- Shell-integration env in panes is injected by the serve (`TERN_*`,
  `KITTY_*`, `TERM=xterm-kitty`); server-side pane environments are identical
  between working and broken panes — a broken pane is a client/renderer
  problem, not a box problem.

## SSH path (fallback / CLI)

- The personal tailnet runs `tailscaled --tun=userspace-networking`
  (homebrew service) with a SOCKS5 proxy on 127.0.0.1:1055; it owns no kernel
  routes. `~/.ssh/config` `Host workstation` uses
  `ProxyCommand nc -x 127.0.0.1:1055 %h %p`.
- Tern.app cannot sign SSH keys through the 1Password agent (the agent
  refuses), so it uses the on-disk key `~/.ssh/tern-workstation`, authorized
  in `users/yuri-workstation.nix` ("tern-app" comment).
