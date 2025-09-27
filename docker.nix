
{ pkgs ? import ./nixpkgs.nix }:

let

  app-client = pkgs.callPackage ./app-client.nix {};

  app = pkgs.callPackage ./default.nix {};

  entrypoint = pkgs.writeScript "entrypoint.sh" ''
    #!${pkgs.stdenv.shell}
    $@
  '';

in {

  misodoc2-serve = pkgs.dockerTools.buildLayeredImage {
    name = "juliendehos/misodoc2";
    tag = "serve";
    created = "now";
    contents = [ "${app-client}" ];
    config = {
      Entrypoint = [ entrypoint ];
      Cmd = [ "${app}/bin/app serve -s ${app-client}/server -i /book" ];
    };
  };

  misodoc2-render = pkgs.dockerTools.buildLayeredImage {
    name = "juliendehos/misodoc2";
    tag = "render";
    created = "now";
    config = {
      Entrypoint = [ entrypoint ];
      Cmd = [ "${app}/bin/app render -o /output -i /book" ];
    };
  };

}

