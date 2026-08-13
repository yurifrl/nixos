# Packages for the workstation agent stack, exposed as an overlay so both
# agents.nix (herdr) and herdr-phone.nix (herdr + herdr-phone) share one
# definition instead of duplicating it.
#
#   - herdr:        pinned prebuilt upstream Linux release (autoPatchelf'd).
#   - herdr-phone:  the remote-access relay built from our fork
#                   (github.com/yurifrl/herdr-phone). The React PWA (web/) is
#                   built with npm and embedded into the Go binary
#                   (internal/webui/generated), exactly as `make build` does.
{ ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      herdr = prev.stdenv.mkDerivation {
        pname = "herdr";
        version = "0.8.0";

        src = prev.fetchurl {
          url = "https://github.com/herdrdev/herdr/releases/download/v0.8.0/herdr-linux-x86_64";
          hash = "sha256-uHLqfkD6LLF+hXrJtisb8m23tAPGIvXS8/WzX26azSg=";
        };

        dontUnpack = true;
        nativeBuildInputs = [ prev.autoPatchelfHook ];
        buildInputs = [ prev.stdenv.cc.cc.lib ];

        installPhase = ''
          runHook preInstall
          install -Dm755 $src $out/bin/herdr
          runHook postInstall
        '';

        meta = with prev.lib; {
          description = "herdr — terminal multiplexer for coding agents";
          homepage = "https://github.com/herdrdev/herdr";
          license = licenses.agpl3Plus;
          mainProgram = "herdr";
          platforms = [ "x86_64-linux" ];
        };
      };

      herdr-phone =
        let
          # The flake's pinned nixpkgs only ships Go up to 1.25, but herdr-phone's
          # go.mod requires >= 1.26.5. Pin a scoped nixpkgs that has go_1_26 for the
          # Go toolchain ONLY (the static CGO-free binary is self-contained), so the
          # system nixpkgs is left untouched.
          goPkgs = import
            (builtins.fetchTarball {
              url = "https://github.com/NixOS/nixpkgs/archive/b7c2ada94fe99c15b0dbcf4d11fd7850b957a436.tar.gz";
              sha256 = "1hw875y585lkhygn09kcbmdgm58b0nb5k0d38qwlvfngprsnp2r0";
            })
            { system = prev.stdenv.hostPlatform.system; };

          src = prev.fetchFromGitHub {
            owner = "yurifrl";
            repo = "herdr-phone";
            rev = "a66207427fd31f3574e102784c3d0ae766571a49";
            sha256 = "1ijwzrnmd8bik4rbas3qb8shmiv76hw0n8nyj9499aybxa2ljq94";
          };

          # The PWA (web/) built to web/dist by `npm run build` (vite).
          web = prev.buildNpmPackage {
            pname = "herdr-phone-web";
            version = "0.4.0";
            inherit src;
            sourceRoot = "${src.name}/web";
            npmDepsHash = "sha256-LP0TnkPND9Z8E777pNFZ3queGDyi/5rvRCKBlQU/wjM=";
            installPhase = ''
              runHook preInstall
              cp -r dist "$out"
              runHook postInstall
            '';
          };
        in
        # go.mod requires go >= 1.26.5; use the scoped nixpkgs' Go 1.26 toolchain.
        (goPkgs.buildGoModule.override { go = goPkgs.go_1_26; }) {
          pname = "herdr-phone";
          version = "0.4.0";
          inherit src;
          vendorHash = "sha256-2L33WDYMmZdDnjU8bx1WvqXMw3XWJleWMv/GENDw5dE=";
          subPackages = [ "cmd/herdr-phone" ];
          env.CGO_ENABLED = "0";
          ldflags = [ "-s" "-w" ];

          # Embed the built frontend into the Go embed tree (internal/webui/generated),
          # mirroring scripts/embed-web.sh, before compilation. Without this the binary
          # only carries the placeholder shell and refuses to start a release serve.
          preBuild = ''
            cp -r ${web}/. internal/webui/generated/
          '';

          # The full suite is validated in the fork's CI / locally; the sandboxed
          # check phase would need network (JWKS) and the embed marker dance.
          doCheck = false;

          meta = with prev.lib; {
            description = "herdr-phone — remote-access relay + PWA for herdr";
            homepage = "https://github.com/yurifrl/herdr-phone";
            license = licenses.mit;
            mainProgram = "herdr-phone";
            platforms = [ "x86_64-linux" ];
          };
        };
    })
  ];
}
