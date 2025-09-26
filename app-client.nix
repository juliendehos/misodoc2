
{ pkgs ? import ./nixpkgs.nix }:

pkgs.stdenv.mkDerivation {
  name = "app-client";
  src = ./.;
  dontBuild = true;
  installPhase = ''
    mkdir $out
    cp -r $src/server $out/
  '';
}

