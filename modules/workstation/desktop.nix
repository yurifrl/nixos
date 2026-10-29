# Desktop + gaming stack, part of the shared workstation image.
#
# Hyprland (dynamic tiling Wayland compositor, the i3 successor) with greetd/
# tuigreet as the login prompt, Steam + gamemode, and the NVIDIA userland
# (incl. 32-bit GL for Steam's 32-bit games) for the RTX 4070 passed through
# on the workstation-gpu Proxmox deploy (VM 103). The same image also boots
# the GPU-less headless deploy (VM 102): the NVIDIA driver is inert there
# (no hardware to bind), Steam/Hyprland simply sit unused, and greetd replaces
# getty on tty1 with an equivalent login prompt.
{ config, pkgs, lib, ... }:
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

  programs.hyprland.enable = true;

  # Game streaming: Sunshine hosts this VM's display to Moonlight clients
  # (Parsec cannot host on Linux). KMS capture (CAP_SYS_ADMIN) grabs the
  # passed-through NVIDIA output even outside a session; the module opens
  # its firewall ports, enables uinput (virtual controllers) and avahi
  # (mDNS discovery on the LAN).
  services.sunshine = {
    enable = true;
    capSysAdmin = true;
    openFirewall = true;
  };

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
    kitty         # Hyprland default terminal binding
    wofi          # Hyprland default launcher binding
    moonlight-qt  # client for other streaming hosts (e.g. the Windows VM)
    vulkan-tools  # vulkaninfo: proves the GPU shows up in the guest
    mesa-demos    # glxinfo: proves GL renders on the passthrough GPU
  ];

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
  ];
}
