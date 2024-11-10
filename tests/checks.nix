{ nixpkgs, quadletModule }:
let
  systems = [ "x86_64-linux" "aarch64-linux" ];
  genTests = system: let
    pkgs = import nixpkgs { inherit system; };
  in {
    basic = pkgs.callPackage ./basic.nix { inherit quadletModule; };
    container = pkgs.callPackage ./container.nix { inherit quadletModule; };
    network = pkgs.callPackage ./network.nix { inherit quadletModule; };
    pod = pkgs.callPackage ./pod.nix { inherit quadletModule; };
  };
in builtins.listToAttrs (map (system: { name = system; value = genTests system; }) systems)
