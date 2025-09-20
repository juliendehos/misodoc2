
{ pkgs ? import ./nixpkgs.nix }:

let

  app-client = pkgs.callPackage ./app-client.nix {};

  app-server = pkgs.callPackage ./app-server.nix {};

  entrypoint = pkgs.writeScript "entrypoint.sh" ''
    #!${pkgs.stdenv.shell}
    $@
  '';


in pkgs.dockerTools.buildLayeredImage {
  name = "juliendehos/misodoc2";
  tag = "latest";
  created = "now";
  contents = [ "${app-client}" ];
  config = {
    Entrypoint = [ entrypoint ];
    Cmd = [ "${app-server}/bin/app" ];
  };

}

