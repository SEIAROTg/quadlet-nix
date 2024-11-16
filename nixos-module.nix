{ libUtils }:
{
  config,
  lib,
  pkgs,
  ...
}@attrs:
with lib;
let
  cfg = config.virtualisation.quadlet;
  quadletUtils = import ./utils.nix {
    inherit lib;
    systemdLib =
      (libUtils {
        inherit lib config pkgs;
      }).systemdUtils.lib;
  };
  # TODO: replace with lib.mergeAttrsList once stable.
  mergeAttrsList = foldl mergeAttrs { };

  containerOpts = types.submodule (import ./container.nix { inherit quadletUtils; });
  networkOpts = types.submodule (import ./network.nix { inherit quadletUtils pkgs; });
  podOpts = types.submodule (import ./pod.nix { inherit quadletUtils; });
in
{
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

      pods = mkOption {
        type = types.attrsOf podOpts;
        default = { };
      };
    };
  };

  config =
    let
      allObjects = (attrValues cfg.containers) ++ (attrValues cfg.networks) ++ (attrValues cfg.pods);
    in
    {
      virtualisation.podman.enable = true;
      assertions =
        let
          containerPodConflicts = lists.intersectLists (attrNames cfg.containers) (attrNames cfg.pods);
        in
        [
          {
            assertion = containerPodConflicts == [ ];
            message = ''
              The container/pod names should be unique!
              See: https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html#podname
              The following names are not unique: ${strings.concatStringsSep " " containerPodConflicts}
            '';
          }
        ];
      environment.etc = mergeAttrsList (
        map (p: {
          "containers/systemd/${p.ref}" = {
            text = p._configText;
            mode = "0600";
          };
        }) allObjects
      );
      # The symlinks are not necessary for the services to be honored by systemd,
      # but necessary for NixOS activation process to pick them up for updates.
      systemd.packages = [
        (pkgs.linkFarm "quadlet-service-symlinks" (
          map (p: {
            name = "etc/systemd/system/${p._unitName}";
            path = "/run/systemd/generator/${p._unitName}";
          }) allObjects
        ))
      ];
      # Inject X-RestartIfChanged=${hash} for NixOS to detect changes.
      systemd.units = mergeAttrsList (
        map (p: {
          ${p._unitName} = {
            overrideStrategy = "asDropin";
            text = "[Unit]\nX-RestartIfChanged=${builtins.hashString "sha256" p._configText}";
          };
        }) allObjects
      );
    };
}
