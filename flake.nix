{
  description = "NixOS and home-manager module for Podman Quadlets";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      libUtils = import "${nixpkgs}/nixos/lib/utils.nix";
    in
    {
      nixosModules.quadlet = import ./nixos-module.nix { inherit libUtils; };
      homeManagerModules.quadlet = import ./home-manager-module.nix { inherit libUtils; };
    };
}
