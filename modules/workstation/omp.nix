# omp (oh-my-pi, https://omp.sh): coding agent with the IDE wired in. Pinned
# prebuilt upstream Linux release, installed VERBATIM — the binary is a Bun
# single-executable (JS payload appended after the ELF); patchelf/autoPatchelf
# rewrites the file and breaks Bun's payload trailer, making omp degrade into
# bare `bun`. Dynamic linker + libs (glibc, libstdc++) are provided by the
# system nix-ld. Version tracks the can1357/tap brew formula the Mac installs
# (sha256 verified against that formula).
{ ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      omp =
        let
          version = "18.1.12";
        in
        prev.runCommand "omp-${version}"
          {
            src = prev.fetchurl {
              url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/omp-linux-x64";
              hash = "sha256-9UMQCPcdLzlxYXIFz86csifB0TVmWTAIgkTHbYay+0I";
            };
            meta = with prev.lib; {
              description = "Coding agent with the IDE wired in";
              homepage = "https://omp.sh";
              license = licenses.mit;
              mainProgram = "omp";
              platforms = [ "x86_64-linux" ];
            };
          }
          ''
            install -Dm755 $src $out/bin/omp
          '';
    })
  ];
}
