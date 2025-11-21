{ lib
, buildGoModule
, fetchFromGitHub
}:
buildGoModule rec {
  pname = "gatus";
  version = "5.32.0";

  src = fetchFromGitHub {
    owner = "TwiN";
    repo = "gatus";
    rev = "v${version}";
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };
 

  vendorHash = null; # Let Nix compute the vendorHash

  meta = with lib; {
    description = "Automated developer-oriented status page";
    homepage = "https://github.com/TwiN/gatus";
    license = licenses.asl20;
    mainProgram = "gatus";
  };
} 
