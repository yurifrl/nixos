# omp (oh-my-pi, https://omp.sh): coding agent with the IDE wired in. Pinned
# prebuilt upstream Linux release, autoPatchelf'd — same shape as herdr in
# ./herdr-packages.nix. Version tracks the can1357/tap brew formula the Mac
# installs (sha256 verified against that formula).
{ ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      omp =
        let
          version = "18.1.12";
        in
        prev.stdenv.mkDerivation {
          pname = "omp";
          inherit version;

          src = prev.fetchurl {
            url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/omp-linux-x64";
            hash = "sha256-9UMQCPcdLzlxYXIFz86csifB0TVmWTAIgkTHbYay+0I";
          };

          dontUnpack = true;
          nativeBuildInputs = [ prev.autoPatchelfHook ];
          buildInputs = [ prev.stdenv.cc.cc.lib ];

          installPhase = ''
            runHook preInstall
            install -Dm755 $src $out/bin/omp
            runHook postInstall
          '';

          meta = with prev.lib; {
            description = "Coding agent with the IDE wired in";
            homepage = "https://omp.sh";
            license = licenses.mit;
            mainProgram = "omp";
            platforms = [ "x86_64-linux" ];
          };
        };
    })
  ];
}
