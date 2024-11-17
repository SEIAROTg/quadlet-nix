{ libUtils }:
{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types mkOption attrValues mergeAttrsList mkIf;

  cfg = config.virtualisation.quadlet;
  quadletUtils = import ./utils.nix {
    inherit lib;
    systemdLib = (libUtils { inherit lib config pkgs; }).systemdUtils.lib;
  };
  containerOpts = types.submodule (import ./container.nix { inherit quadletUtils; });
  networkOpts = types.submodule (import ./network.nix { inherit quadletUtils pkgs; });
  podOpts = types.submodule (import ./pod.nix { inherit quadletUtils; });
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
      assertions = [
        {
          assertion = builtins.isInt osConfig.users.users.${config.home.username}.uid;
          message = ''
            users.users.${config.home.username}.uid must be set.
          '';
        }
      ];

      xdg.configFile =
        let
          links = pkgs.linkFarm "user-quadlet-service-symlinks" (
            map (p: {
              name = p._unitName;
              # TODO: remove reliance on uid in config
              path = "/run/user/${
                toString osConfig.users.users.${config.home.username}.uid
              }/systemd/generator/${p._unitName}";
            }) allObjects
          );
        in
        mergeAttrsList (
          map (p: {
            # Install the .container, .network, etc files
            "containers/systemd/${p.ref}" = {
              text = p._configText;
            };
            # Link the corresponding .service files so that the home-manager activation process knows about them
            "systemd/user/${p._unitName}" = {
              source = "${links}/${p._unitName}";
            };
            # Inject X-RestartIfChanged=${hash} for NixOS to detect changes.
            "systemd/user/${p._unitName}.d/override.conf" = {
              text = "[Unit]\nX-RestartIfChanged=${builtins.hashString "sha256" p._configText}";
            };
          }) allObjects
        );
      # This is crucial to ensure the systemd services are (re)started
      systemd.user.startServices = "sd-switch";
      systemd.user.services.podman-auto-update = mkIf cfg.autoUpdate.enable {
        Unit = {
          Description = "Podman auto-update service";
          Documentation = "man:podman-auto-update(1)";
        };
        Service = {
          Type = "oneshot";
          # podman rootless requires "newuidmap" (the suid version, not the non-suid one from pkgs.shadow)
          Environment = "PATH=/run/wrappers/bin";
          ExecStart = "${pkgs.podman}/bin/podman auto-update";
          ExecStartPost = "${pkgs.podman}/bin/podman image prune -f";
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
