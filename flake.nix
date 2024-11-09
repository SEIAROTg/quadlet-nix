{
  description = "NixOS module for Podman Quadlet";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      libUtils = import "${nixpkgs}/nixos/lib/utils.nix";
      quadletModule = import ./nixos-module.nix { inherit libUtils; };
    in
    {
      nixosModules.quadlet = quadletModule;

      checks = import ./tests/checks.nix { inherit nixpkgs; inherit quadletModule; };
  };
}
