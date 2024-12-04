{ libUtils }:
{
  config,
  osConfig ? { },
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types mkOption attrValues mergeAttrsList mkIf getExe;

  cfg = config.virtualisation.quadlet;
  quadletUtils = import ./utils.nix {
    inherit lib;
    systemdLib = (libUtils { inherit lib config pkgs; }).systemdUtils.lib;
    isUserSystemd = true;
    podmanPackage = osConfig.virtualisation.podman.package or pkgs.podman;
  };
  containerOpts = types.submodule (import ./container.nix { inherit quadletUtils; });
  networkOpts = types.submodule (import ./network.nix { inherit quadletUtils; });
  podOpts = types.submodule (import ./pod.nix { inherit quadletUtils; });

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
  config =
    let
      allObjects = (attrValues cfg.containers) ++ (attrValues cfg.networks) ++ (attrValues cfg.pods);
    in
    {
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
            # Inject hash for the activation process to detect changes.
            # Must be in the main file as it's the only thing home-manager switch process looks at.
            "systemd/user/${p._unitName}" = {
              text = ''
                [Unit]
                X-QuadletNixConfigHash=${builtins.hashString "sha256" p._configText}
                [Service]
                Environment=PATH=/run/wrappers/bin
              '';
            };
            # Import quadlet-generated unit as a dropin override.
            "systemd/user/${p._unitName}.d/override.conf" = {
              source = "${configPathLink}/out/${p._unitName}";
            };
          }) allObjects
        ) // {
          # the stock service uses `sh` instead of `/bin/sh`.
          # systemd only looks for command binary in a few static location.
          # See: https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html#Command%20lines
          "systemd/user/podman-user-wait-network-online.service.d/override.conf" = {
            text = ''
              [Service]
              ExecStart=
              ExecStart=/bin/sh -c 'until systemctl is-active network-online.target; do sleep 0.5; done'
              [Install]
              WantedBy=default.target
            '';
          };
        };
      # TODO: link from ${pkgs.podman}/share/systemd/user/podman-auto-update.service
      # when https://github.com/containers/podman/issues/24637 is fixed.
      systemd.user.services.podman-auto-update = mkIf cfg.autoUpdate.enable {
        Unit = {
          Description = "Podman auto-update service";
          Documentation = "man:podman-auto-update(1)";
        };
        Service = {
          Type = "oneshot";
          # podman rootless requires "newuidmap" (the suid version, not the non-suid one from pkgs.shadow)
          Environment = "PATH=/run/wrappers/bin";
          ExecStart = "${getExe quadletUtils.podmanPackage} auto-update";
          ExecStartPost = "${getExe quadletUtils.podmanPackage} image prune -f";
          TimeoutStartSec = "900s";
          TimeoutStopSec = "10s";
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
