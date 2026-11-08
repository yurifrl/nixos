# Desktop + gaming stack, part of the shared workstation image.
#
# Hyprland (dynamic tiling Wayland compositor, the i3 successor) with greetd
# autologin, Steam + gamemode, and the NVIDIA userland (incl. 32-bit GL for
# Steam's 32-bit games) for the RTX 4070 passed through on the
# workstation-gpu config of the workstation VM (VM 102 — same machine, GPU
# mode on). The same image also boots the GPU-less headless config: the
# NVIDIA driver is inert there (no hardware to bind) and the session is
# streamed by Sunshine instead of shown on a physical monitor.
{ config, pkgs, lib, inputs, ... }:
let
  # Sunshine from the dedicated nixpkgs-sunshine pin (v2026.914.233613,
  # GHSA-fp6g-27w5-489j high-severity Linux fix — the host's pinned nixpkgs
  # still ships 2025.924).
  sunshinePkg = inputs.nixpkgs-sunshine.legacyPackages.x86_64-linux.sunshine;

  # Lutris 0.5.22 from the dedicated pin (host nixpkgs ships 0.5.19).
  lutrisPkg = inputs.nixpkgs-lutris.legacyPackages.x86_64-linux.lutris.override {
    steamSupport = false; # Steam runs separately; avoids pulling unfree steam-unwrapped
  };
  # Headless session: greetd auto-logs in (initial_session) straight into
  # Hyprland on the DRM output. Hyprland MUST grab DRM master first —
  # Sunshine started before it would steal master and kill the compositor.
  # The compositor's config starts Sunshine via exec-once once the session
  # is up (activation script below creates the config create-if-absent).
  sunshineHeadlessSession = pkgs.writeShellScriptBin "sunshine-headless-session" ''
    exec ${config.programs.hyprland.package}/bin/Hyprland
  '';
in
{
  # NVIDIA GPU passed through from pc01 (hostpci0 x-vga). videoDrivers makes
  # the module stack available; modesetting is required for Wayland/Hyprland.
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    # RTX 4070 (AD104, Ada) — Turing+ => open kernel modules (required to be
    # explicit for driver >= 560).
    modesetting.enable = true;
    open = true;
    # Stable driver branch.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Wayland/EGL/Vulkan userland + 32-bit (Steam's 32-bit games).
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Standard NVIDIA-on-Wayland session variables (Hyprland wiki) + native
  # Wayland for Electron apps.
  environment.sessionVariables = {
    GBM_BACKEND = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    NIXOS_OZONE_WL = "1";
  };

  # Wayland session. greetd (below) launches Hyprland via the headless
  # Sunshine wrapper. Portals + dconf so GTK/Qt apps behave under Wayland
  # (screen sharing, file dialogs, dark-mode settings).
  programs.hyprland.enable = true;

  programs.dconf.enable = true;

  # AppImages (WowUp) execute directly via binfmt — no FUSE dance, they run
  # from the file manager or terminal like normal binaries.
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  xdg.portal = {
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
  };
  # Deliver configs create-if-absent (user edits survive rebuilds):
  # - hyprland.conf: exec-once starts Sunshine only after the session exists,
  #   so Hyprland keeps DRM master and Sunshine captures the live session.
  # - sunshine.conf: v2026.914 aborts startup when the system tray cannot be
  #   created — headless boxes have no tray.
  # - workstation binds: the stock Super+R launcher bind is useless from a
  #   Mac (macOS eats Cmd/Super combos before Moonlight sees them), so the
  #   launcher and terminal also live on Ctrl+Alt combos. Hyprland live-
  #   reloads its config, so appended binds activate immediately.
  system.activationScripts.sunshineHyprlandConf = lib.stringAfter [ "users" ] ''
    conf="/home/yuri-workstation/.config/hypr/hyprland.conf"
    if [ ! -f "$conf" ]; then
      mkdir -p "$(dirname "$conf")"
      printf 'exec-once = systemctl --user start sunshine.service\n' > "$conf"
      chown yuri-workstation:users "$conf"
    fi
    if ! grep -q 'workstation-binds' "$conf"; then
      printf '\n# workstation-binds (mac-safe; macOS eats Cmd/Super combos)\n' >> "$conf"
      printf 'bind = CTRL ALT, Space, exec, wofi --show drun\n' >> "$conf"
      printf 'bind = CTRL ALT, Return, exec, kitty\n' >> "$conf"
      printf 'bind = CTRL ALT, W, exec, wofi --show window\n' >> "$conf"
      chown yuri-workstation:users "$conf"
    fi
    # The EDID-detected mode is 4096x2160@24 (odd aspect, 4x the pixels a
    # software encoder can push smoothly). Moonlight streams 16:9 — pin the
    # output to 1080p60. Hyprland live-reloads this instantly.
    if ! grep -q '^monitor = HDMI-A-1' "$conf"; then
      printf 'monitor = HDMI-A-1, 1920x1080@60, 0x0, 1\n' >> "$conf"
      chown yuri-workstation:users "$conf"
    fi
    conf2="/home/yuri-workstation/.config/sunshine/sunshine.conf"
    if [ ! -f "$conf2" ]; then
      mkdir -p "$(dirname "$conf2")"
      printf 'system_tray = disabled\n' > "$conf2"
      chown yuri-workstation:users "$conf2"
    fi
    grep -q '^system_tray' "$conf2" || printf 'system_tray = disabled\n' >> "$conf2"
    # v2026.914 tries the RemoteDesktop portal first and fails on it (GDBus
    # error); wlgrab works headless — pin it explicitly so startup completes.
    grep -q '^capture' "$conf2" || printf 'capture = wlr\n' >> "$conf2"
    chown yuri-workstation:users "$conf2"
  '';

  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "${sunshineHeadlessSession}/bin/sunshine-headless-session";
        user = "yuri-workstation";
      };
      default_session.command =
        "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
    };
  };

  # Sunshine needs cap_sys_admin for KMS capture on the DRM output, so the
  # binary is exposed as a root-owned capability wrapper instead of running
  # it directly from the store.
  security.wrappers.sunshine = {
    source = "${sunshinePkg}/bin/sunshine";
    owner = "root";
    group = "root";
    capabilities = "cap_setpcap,cap_sys_admin=p";
    permissions = "u=rx,g=x,o=x";
  };

  # Stream host as a user service — the Hyprland exec-once starts it with
  # `systemctl --user start sunshine.service`; it binds graphical-session
  # lifecycle for any other management entry points.
  systemd.user.services.sunshine = {
    description = "Self-hosted game stream host for Moonlight";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "/run/wrappers/bin/sunshine";
      Restart = "on-failure";
      RestartSec = "5s";
    };
    # v2026.914 prep-cmds shell out to setsid (util-linux) and session tools;
    # the user-manager's minimal PATH lacks them, which aborted startup before
    # the ports ever bound.
    environment.PATH = lib.mkForce "/run/wrappers/bin:/run/current-system/sw/bin";
  };

  # Moonlight reaches the stream host from other machines: Sunshine's
  # control ports (HTTPS pairing 47984, HTTP 47989, web UI 47990) and the
  # RTP/RTSP media streams (TCP + UDP 48010, UDP 47998-48000).
  networking.firewall = {
    allowedTCPPorts = [
      47984
      47989
      47990
      48010
    ];
    allowedUDPPorts = [
      47998
      47999
      48000
      48010
    ];
  };

  programs.steam = {
    enable = true;
    # Steam Remote Play / streaming over the LAN without manual firewall holes.
    remotePlay.openFirewall = true;
  };
  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    kitty         # Hyprland default terminal binding
    wofi          # Hyprland default launcher binding
    moonlight-qt  # client for other streaming hosts (e.g. the Windows VM)
    sunshinePkg   # stream host (started via the capability wrapper, see above)
    vulkan-tools  # vulkaninfo: proves the GPU shows up in the guest
    mesa-demos    # glxinfo: proves GL renders on the passthrough GPU
lutrisPkg       # WoW without Steam: Battle.net under managed Wine runners
    wineWowPackages.stable  # Wine 10 WoW64 — 32-bit Windows apps, no multilib
  ];

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
  ];
}
