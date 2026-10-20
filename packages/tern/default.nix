{ lib
, stdenv
, autoPatchelfHook
, webkitgtk_4_1
, wpebackend-fdo
, gtk3
, glib
, wayland
, mesa
, libxkbcommon
, pulseaudio
, pipewire
, linux-pam
, vulkan-loader
, libgcc
}:

stdenv.mkDerivation {
  pname = "tern";
  version = "0.9.3";

  # Upstream distributes via presigned URLs that expire, so the tarball is
  # vendored. sha256: 20BUPgMWW04lK/rnsKovfwN6QrThqO/34hIdtNDHfXc=
  src = ./Tern-0.9.3-linux-x86_64.tar.gz;

  nativeBuildInputs = [ autoPatchelfHook ];

  # Direct DT_NEEDED is glibc-only, but the binary dlopens GUI/audio libs at
  # runtime; listing them here lets autoPatchelfHook bake a RUNPATH that
  # covers dlopen().
  buildInputs = [
    stdenv.cc.cc.lib
    libgcc
    webkitgtk_4_1
    wpebackend-fdo
    gtk3
    glib
    wayland
    mesa
    libxkbcommon
    pulseaudio
    pipewire
    linux-pam
    vulkan-loader
  ];

  sourceRoot = "tern";

  installPhase = ''
    runHook preInstall
    install -Dm755 tern $out/bin/tern
    runHook postInstall
  '';

  meta = with lib; {
    description = "Tern app from stencil.so (vendored binary)";
    homepage = "https://docs.stencil.so/tern";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "tern";
  };
}
