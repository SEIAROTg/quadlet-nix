{ libUtils }:
{
  config,
  osConfig,
  options,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.virtualisation.user.quadlet;
  quadletUtils = import ./utils.nix {
    inherit lib;
    systemdLib = (libUtils { inherit lib config pkgs; }).systemdUtils.lib;
  };
  containerOpts = lib.types.submodule (import ./container.nix { inherit quadletUtils; });
  networkOpts = lib.types.submodule (import ./network.nix { inherit quadletUtils pkgs; });
in
{
  options.virtualisation.user.quadlet = {
    autoUpdate = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      calendar = lib.mkOption {
        type = lib.types.str;
        default = "*-*-* 00:00:00";
      };
    };
    containers = lib.mkOption {
      type = lib.types.attrsOf containerOpts;
      default = { };
    };
    networks = lib.mkOption {
      type = lib.types.attrsOf networkOpts;
      default = { };
    };
  };
  config =
    let
      allObjects = (lib.attrValues cfg.containers) ++ (lib.attrValues cfg.networks);
    in
    {
      xdg.configFile =
        let
          links = pkgs.linkFarm "user-quadlet-service-symlinks" (
            map (p: {
              name = p._unitName;
              path = "/run/user/${
                toString osConfig.users.users.${config.home.username}.uid
              }/systemd/generator/${p._unitName}";
            }) allObjects
          );
        in
        lib.mergeAttrsList (
          map (p: {
            # Install the .container, .network, etc files
            "containers/systemd/${p._configName}" = {
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
      systemd.user.services.podman-auto-update = lib.mkIf cfg.autoUpdate.enable {
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
      systemd.user.timers.podman-auto-update = lib.mkIf cfg.autoUpdate.enable {
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
