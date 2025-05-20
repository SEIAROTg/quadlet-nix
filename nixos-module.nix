{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types lists strings mkOption attrNames attrValues mergeAttrsList;

  cfg = config.virtualisation.quadlet;
  quadletUtils = import ./utils.nix {
    inherit lib;
    inherit (import (pkgs.path + "/nixos/lib/utils.nix") { inherit lib config pkgs; }) systemdUtils;
    podmanPackage = config.virtualisation.podman.package;
    autoEscape = config.virtualisation.quadlet.autoEscape;
  };

  buildOpts = types.submodule (import ./build.nix { inherit quadletUtils; });
  containerOpts = types.submodule (import ./container.nix { inherit quadletUtils; });
  networkOpts = types.submodule (import ./network.nix { inherit quadletUtils; });
  podOpts = types.submodule (import ./pod.nix { inherit quadletUtils; });
  volumeOpts = types.submodule (import ./volume.nix { inherit quadletUtils; });
in
{
  options = {
    virtualisation.quadlet = {
      builds = mkOption {
        type = types.attrsOf buildOpts;
        default = { };
      };

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

      volumes = mkOption {
        type = types.attrsOf volumeOpts;
        default = { };
      };

      autoEscape = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enables appropriate quoting / escaping.

          Not enabled by default to avoid breaking existing configurations. In the future this will be required.
        '';
      };
    };
  };

  config =
    let
      allObjects = builtins.concatLists (map attrValues [
        cfg.builds
        cfg.containers
        cfg.networks
        cfg.pods
        cfg.volumes
      ]);
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
      warnings =
        quadletUtils.assertionsToWarnings [
          {
            assertion = !(builtins.any (p: p._autoEscapeRequired) allObjects);
            message = ''
              `virtualisation.quadlet.autoEscape = true` is required because this configuration contains characters that require quoting or escaping.

              This will become a hard error in the future. If you have manual quoting or escaping in place, please undo those and enable `autoEscape`.
            '';
          }
        ];
      environment.etc = mergeAttrsList (
        map (p: {
          "containers/systemd/${p.ref}" = {
            text = p._configText;
            mode = "0600";
          };
        }) allObjects);
      # The symlinks are not necessary for the services to be honored by systemd,
      # but necessary for NixOS activation process to pick them up for updates.
      systemd.packages = [
        (pkgs.linkFarm "quadlet-service-symlinks" (
          map (p: {
            name = "etc/systemd/system/${p._serviceName}.service";
            path = "/run/systemd/generator/${p._serviceName}.service";
          }) allObjects
        ))
      ];
      # Inject X-RestartIfChanged=${hash} for NixOS to detect changes.
      systemd.units = mergeAttrsList (
        map (p: {
          "${p._serviceName}.service" = {
            overrideStrategy = "asDropin";
            text = quadletUtils.unitConfigToText {
              Unit.X-QuadletNixConfigHash = builtins.hashString "sha256" p._configText;
            };
            # systemd recommends multi-user.target over default.target.
            # https://www.freedesktop.org/software/systemd/man/latest/systemd.special.html#default.target
            wantedBy = if p._autoStart then [ "multi-user.target" ] else [];
          };
        }) allObjects
      );
    };
}
