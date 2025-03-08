# A wrapper around cowsay that displays version numbers
{ writeShellScriptBin, cowsay }:

let
  script = ''
    #!/bin/sh
    ${cowsay}/bin/cowsay "$1.0.0"
  '';
in
writeShellScriptBin "cowsay-version" script 