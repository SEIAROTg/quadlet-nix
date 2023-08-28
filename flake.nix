{
  description = "NixOS module for Podman Quadlet";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, ... }:
  let
    systemdLib = import "${nixpkgs}/nixos/lib/systemd-lib.nix";
  in {
    nixosModules.quadlet = import ./nixos-module.nix { inherit systemdLib; };
  };
}
