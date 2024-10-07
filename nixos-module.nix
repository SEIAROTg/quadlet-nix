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
      containerAndPodObjects = (attrValues cfg.containers) ++ (attrValues cfg.pods);
      allObjects = (attrValues cfg.containers) ++ (attrValues cfg.networks) ++ (attrValues cfg.pods);
    in
    {
      virtualisation.podman.enable = true;
      assertions =
        let
          count_occurances =
            str_list:
            lib.lists.foldl' (
              acc: el: if acc ? ${el} then acc // { ${el} = acc.${el} + 1; } else acc // { ${el} = 1; }
            ) { } str_list;
          find_duplicate_elements =
            str_l: lib.attrsets.attrNames (lib.attrsets.filterAttrs (_: v: v > 1) (count_occurances str_l));
          # assuming that only `name` defines the final name without the suffix!
          # Containers and pods cannot have the same name!
          duplicate_elements = find_duplicate_elements (map (x: x._name) containerAndPodObjects);
        in
        [
          {
            assertion = duplicate_elements == [ ];
            message = ''
              The container/pod names should be unique!
              See: https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html#podname
              The following names are not unique: ${lib.strings.concatStringsSep " " duplicate_elements}
            '';
          }
        ];
      environment.etc = mergeAttrsList (
        map (p: {
          "containers/systemd/${p._configName}" = {
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
