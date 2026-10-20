# Custom package collection
{ pkgs ? import <nixpkgs> {} }:

{
  # Add your custom packages here
  # Example:
  # my-package = pkgs.callPackage ./my-package {};

  # Cowsay version wrapper
  cowsay-version = pkgs.callPackage ./cowsay-version {
    inherit (pkgs) writeShellScriptBin cowsay;
  };
  
  # Gatus - Developer-oriented status page
  gatus = pkgs.callPackage ./gatus {};

  # Tern - stencil.so app (vendored tarball; upstream URL is presigned/expiring)
  tern = pkgs.callPackage ./tern {};
} 