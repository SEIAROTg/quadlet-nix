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
        );
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
