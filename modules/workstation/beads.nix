# beads (bd): AI-agent issue tracker — pinned prebuilt upstream Linux release.
# Same pattern as herdr: fetch the release tarball, extract the binary.
# To update: bump version + hash (check github.com/gastownhall/beads/releases).
{ ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      beads = prev.stdenv.mkDerivation {
        pname = "beads";
        version = "1.2.2";

        src = prev.fetchurl {
          url = "https://github.com/gastownhall/beads/releases/download/v1.2.2/beads_1.2.2_linux_amd64.tar.gz";
          hash = "sha256-gUAJilHTuB1VSNHF5tsaLZkw5dFB7+Kkv/fQecTTIeg=";
        };

        sourceRoot = ".";
        nativeBuildInputs = [ prev.autoPatchelfHook ];
        buildInputs = [ prev.stdenv.cc.cc.lib ];

        installPhase = ''
          runHook preInstall
          install -Dm755 bd $out/bin/bd
          runHook postInstall
        '';

        meta = with prev.lib; {
          description = "beads — AI-agent issue tracker";
          homepage = "https://github.com/gastownhall/beads";
          license = licenses.mit;
          mainProgram = "bd";
          platforms = [ "x86_64-linux" ];
        };
      };
    })
  ];
}
