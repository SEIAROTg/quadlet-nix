{ libUtils }:
{
  config,
  osConfig ? { },
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types lists strings mkOption attrNames attrValues mergeAttrsList mkIf getExe;

  cfg = config.virtualisation.quadlet;
  quadletUtils = import ./utils.nix {
    inherit lib;
    systemdUtils = (libUtils { inherit lib config pkgs; }).systemdUtils;
    podmanPackage = osConfig.virtualisation.podman.package or pkgs.podman;
    autoEscape = config.virtualisation.quadlet.autoEscape;
  };
  buildOpts = types.submodule (import ./build.nix { inherit quadletUtils; });
  containerOpts = types.submodule (import ./container.nix { inherit quadletUtils; });
  networkOpts = types.submodule (import ./network.nix { inherit quadletUtils; });
  podOpts = types.submodule (import ./pod.nix { inherit quadletUtils; });
  volumeOpts = types.submodule (import ./volume.nix { inherit quadletUtils; });

  activationScript = lib.hm.dag.entryBefore [ "reloadSystemd" ] ''
    mkdir -p '${config.xdg.configHome}/quadlet-nix/'
    ln -sf "''${XDG_RUNTIME_DIR:-/run/user/$UID}/systemd/generator/" '${config.xdg.configHome}/quadlet-nix/out'
  '';
in
{
  options.virtualisation.quadlet = {
    autoUpdate = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
      calendar = mkOption {
        type = types.str;
        default = "*-*-* 00:00:00";
      };
    };
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
            assertion = cfg.autoEscape || !(builtins.any (p: p._autoEscapeRequired) allObjects);
            message = ''
              `virtualisation.quadlet.autoEscape = true` is required because this configuration contains characters that require quoting or escaping.

              This will become a hard error in the future. If you have manual quoting or escaping in place, please undo those and enable `autoEscape`.
            '';
          }
        ];

      home.activation.quadletNix = mkIf (lib.length allObjects > 0) activationScript;

      xdg.configFile =
        let
          configPathLink = (pkgs.linkFarm "quadlet-out-path" [{
            name = "quadlet-nix";
            path = "${config.xdg.configHome}/quadlet-nix";
          }]) + "/quadlet-nix";
        in
        mergeAttrsList (
          map (p: {
            # Install the .container, .network, etc files
            "containers/systemd/${p.ref}" = {
              text = p._configText;
            };
            # Import quadlet-generated unit as a dropin override.
            "systemd/user/${p._serviceName}.service.d/override.conf" = {
              source = "${configPathLink}/out/${p._serviceName}.service";
            };
          }) allObjects
        ) // {
          # the stock service uses `sh` instead of `/bin/sh`.
          # systemd only looks for command binary in a few static location.
          # See: https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html#Command%20lines
          "systemd/user/podman-user-wait-network-online.service.d/override.conf" = {
            text = quadletUtils.unitConfigToText {
              Service.ExecSearchPath = [ "/run/current-system/sw/bin/" ];
            };
          };
        };

      systemd.user.services = mergeAttrsList (
        map (p: {
          # Inject hash for the activation process to detect changes.
          # Must be in the main file as it's the only thing home-manager switch process looks at.
          # WantedBy must be set through `systemd.user.services` which generates .targets.wants symlinks.
          # sd-switch only starts new services with those symlinks.
          ${p._serviceName} = {
            Unit.X-QuadletNixConfigHash = builtins.hashString "sha256" p._configText;
            Install.WantedBy = if p._autoStart then [ "default.target" ] else [];
          };
        }) allObjects
      ) // {
        # TODO: link from ${pkgs.podman}/share/systemd/user/podman-auto-update.service
        # when https://github.com/containers/podman/issues/24637 is fixed.
        podman-auto-update = mkIf cfg.autoUpdate.enable {
          Unit = {
            Description = "Podman auto-update service";
            Documentation = "man:podman-auto-update(1)";
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${getExe quadletUtils.podmanPackage} auto-update";
            ExecStartPost = "${getExe quadletUtils.podmanPackage} image prune -f";
            TimeoutStartSec = "900s";
            TimeoutStopSec = "10s";
          };
        };
      };

      systemd.user.timers.podman-auto-update = mkIf cfg.autoUpdate.enable {
        Unit = {
          Description = "Podman auto-update timer";
          Documentation = "man:podman-auto-update(1)";
        };
        Timer = {
          OnCalendar = cfg.autoUpdate.calendar;
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
}
