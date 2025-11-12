{ lib
, buildGoModule
, fetchFromGitHub
}:
buildGoModule rec {
  pname = "gatus";
  # Testing renovate actually updating the version 5.22.0
  version = "5.31.0";

  src = fetchFromGitHub {
    owner = "TwiN";
    repo = "gatus";
    rev = "v${version}";
    sha256 = "0wzgxs8l33mdknpq0v5ppw981vzdi1v5jyjdbngwkjyrx3zsmyy5"; # nix-prefetch-url --unpack https://github.com/TwiN/gatus/archive/refs/tags/v5.22.0.tar.gz
  };
 

  vendorHash = null; # Let Nix compute the vendorHash

  meta = with lib; {
    description = "Automated developer-oriented status page";
    homepage = "https://github.com/TwiN/gatus";
    license = licenses.asl20;
    mainProgram = "gatus";
  };
} 
