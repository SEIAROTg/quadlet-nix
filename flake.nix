{
  description = "NixOS module for Podman Quadlet";

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
    };
}
