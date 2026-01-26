{
  description = "NixOS and home-manager module for Podman Quadlets";

  outputs =
    { self }:
    {
      nixosModules.quadlet = ./nixos-module.nix;
      homeManagerModules.quadlet = ./home-manager-module.nix;
    };
}
