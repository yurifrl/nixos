# Desktop + gaming stack for the workstation-gpu VM (NVIDIA passthrough guest).
#
# Hyprland (dynamic tiling Wayland compositor, the i3 successor) with greetd/
# tuigreet as the login prompt, Steam + gamemode, and the full NVIDIA userland
# (incl. 32-bit GL for Steam's 32-bit games). Only imported by the
# workstation-gpu host: the headless workstation stays server-shaped and this
# module's NVIDIA driver stack would be dead weight there.
{ config, pkgs, lib, ... }:
{
  # NVIDIA GPU passed through from pc01 (hostpci0 x-vga). videoDrivers makes
  # the module stack available; modeset is required for Wayland/Hyprland.
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    # RTX 4070 (AD104, Ada) passed through from pc01 — Turing+ => open kernel
    # modules (required to be explicit for driver >= 560).
    modesetting.enable = true;         # required for Wayland/Hyprland
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

  programs.hyprland.enable = true;

  # Minimal TUI login on the passed-through display (no display manager).
  services.greetd = {
    enable = true;
    settings.default_session.command =
      "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
  };

  programs.steam = {
    enable = true;
    # Steam Remote Play / streaming over the LAN without manual firewall holes.
    remotePlay.openFirewall = true;
  };
  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    kitty        # Hyprland default terminal binding
    wofi         # Hyprland default launcher binding
    vulkan-tools # vulkaninfo: proves the GPU shows up in the guest
    mesa-demos   # glxinfo: proves GL renders on the passthrough GPU
  ];

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
  ];
}
