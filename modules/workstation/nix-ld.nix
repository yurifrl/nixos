# nix-ld: run dynamically-linked prebuilt binaries (bun/node native modules,
# downloaded toolchains, etc.) on NixOS. Without this, prebuilt .so/.node files
# fail to load because NixOS has no standard /lib64 dynamic linker + libraries.
#
# This is a dev-box platform capability, not a per-app hack: it makes arbitrary
# prebuilt native deps work from ~/Workdir checkouts. board-games' `sharp`
# (libvips) needs libstdc++ here; the rest of libvips is bundled in its package.
{ pkgs, ... }:
{
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib   # libstdc++.so.6, libgcc_s.so.1
    zlib
    openssl
  ];
}
