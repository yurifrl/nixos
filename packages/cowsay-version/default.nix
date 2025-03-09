# A wrapper around cowsay that displays version numbers
{ writeShellScriptBin, cowsay }:

let
  script = ''
    #!/bin/sh
    ${cowsay}/bin/cowsay "$1 v1.0.1"
  '';
in
writeShellScriptBin "cowsay-version" script 