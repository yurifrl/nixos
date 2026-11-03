# Desktop + gaming stack, part of the shared workstation image.
#
# Hyprland (dynamic tiling Wayland compositor, the i3 successor) with greetd
# autologin, Steam + gamemode, and the NVIDIA userland (incl. 32-bit GL for
# Steam's 32-bit games) for the RTX 4070 passed through on the
# workstation-gpu config of the workstation VM (VM 102 — same machine, GPU
# mode on). The same image also boots the GPU-less headless config: the
# NVIDIA driver is inert there (no hardware to bind) and the session is
# streamed by Sunshine instead of shown on a physical monitor.
{ config, pkgs, lib, ... }:
let
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

  xdg.portal = {
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  # Deliver the compositor config create-if-absent (user edits survive
  # rebuilds). exec-once starts Sunshine only after the session exists, so
  # Hyprland keeps DRM master and Sunshine captures the live session.
  system.activationScripts.sunshineHyprlandConf = lib.stringAfter [ "users" ] ''
    conf="/home/yuri-workstation/.config/hypr/hyprland.conf"
    if [ ! -f "$conf" ]; then
      mkdir -p "$(dirname "$conf")"
      printf 'exec-once = systemctl --user start sunshine.service\n' > "$conf"
      chown yuri-workstation:users "$conf"
    fi
  '';

  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "${sunshineHeadlessSession}/bin/sunshine-headless-session";
        user = "yuri-workstation";
      };
      default_session.command =
        "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
    };
  };

  # Sunshine needs cap_sys_admin for KMS capture on the DRM output, so the
  # binary is exposed as a root-owned capability wrapper instead of running
  # it directly from the store.
  security.wrappers.sunshine = {
    source = "${pkgs.sunshine}/bin/sunshine";
    owner = "root";
    group = "root";
    capabilities = "cap_setpcap,cap_sys_admin=p";
    permissions = "u=rx,g=x,o=x";
  };

  # Stream host as a user service — the greetd wrapper starts it with
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
    sunshine      # stream host (started via the capability wrapper, see above)
    vulkan-tools  # vulkaninfo: proves the GPU shows up in the guest
    mesa-demos    # glxinfo: proves GL renders on the passthrough GPU
  ];

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
  ];
}
