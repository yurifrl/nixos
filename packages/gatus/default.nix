{ lib
, buildGoModule
, fetchFromGitHub
}:
buildGoModule rec {
  pname = "gatus";
  # Testing renovate actually updating the version 5.16.0
  version = "5.15.0";

  src = fetchFromGitHub {
    owner = "TwiN";
    repo = "gatus";
    rev = "v${version}";
    sha256 = "sha256-0000000000000000000000000000000000000000000=";
  };

  vendorHash = null; # Let Nix compute the vendorHash

  meta = with lib; {
    description = "Automated developer-oriented status page";
    homepage = "https://github.com/TwiN/gatus";
    license = licenses.asl20;
    mainProgram = "gatus";
  };
} 