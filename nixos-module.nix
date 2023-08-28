{ systemdLib }:
{ config, lib, pkgs, ... }@attrs:

with lib;

let
  cfg = config.virtualisation.quadlet;
  quadletUtils = import ./utils.nix {
    inherit lib;
    systemdLib = systemdLib {
      inherit lib config pkgs;
    };
  };
  # TODO: replace with lib.mergeAttrsList once stable.
  mergeAttrsList = foldl mergeAttrs {};

  containerOpts = types.submodule (import ./container.nix { inherit quadletUtils; } );
  networkOpts = types.submodule (import ./network.nix { inherit quadletUtils pkgs; } );
in {
  options = {
    virtualisation.quadlet = {
      containers = mkOption {
        type = types.attrsOf containerOpts;
        default = { };
      };

      networks = mkOption {
        type = types.attrsOf networkOpts;
        default = { };
      };
    };
  };

  config = {
    virtualisation.podman.enable = true;
    environment.etc = mergeAttrsList (concatLists [
      (map (p: p._etc) (attrValues cfg.containers))
      (map (p: p._etc) (attrValues cfg.networks))
    ]);
    systemd.services = mergeAttrsList (concatLists [
      (map (p: p._services) (attrValues cfg.containers))
      (map (p: p._services) (attrValues cfg.networks))
    ]);
  };
}
