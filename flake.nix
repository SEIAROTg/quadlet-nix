{
  description = "NixOS and home-manager module for Podman Quadlets";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      libUtils = import "${nixpkgs}/nixos/lib/utils.nix";
      quadletModule = import ./nixos-module.nix { inherit libUtils; };
      homeManagerModule = import ./home-manager-module.nix { inherit libUtils; };
    in
    {
      nixosModules.quadlet = quadletModule;
      homeManagerModules.quadlet = homeManagerModule;

      checks = import ./tests/checks.nix { inherit nixpkgs; inherit quadletModule; };
    };
}
