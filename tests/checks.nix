{ nixpkgs, quadletModule }:
let
  systems = [ "x86_64-linux" "aarch64-linux" ];
  genTests = system: let
    pkgs = import nixpkgs { inherit system; };
  in {
    basic = pkgs.callPackage ./basic.nix { inherit quadletModule; };
  };
in builtins.listToAttrs (map (system: { name = system; value = genTests system; }) systems)
