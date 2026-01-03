{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mergeAttrsList mkIf;

  cfg = config.virtualisation.quadlet;
  quadletUtils = import ./utils.nix {
    inherit lib;
    inherit (import (pkgs.path + "/nixos/lib/utils.nix") { inherit lib config pkgs; }) systemdUtils;
    podmanPackage = config.virtualisation.podman.package;
    autoEscape = config.virtualisation.quadlet.autoEscape;
  };
  quadletOptions = import ./options.nix {
    inherit lib quadletUtils;
  };
in
{
  options.virtualisation.quadlet = quadletOptions.mkTopLevelOptions { };

  config =
    let
      allObjects = quadletOptions.getAllObjects cfg;
      # TODO: switch to `cfg.enable == true || (cfg.enable == null && allObjects != [])`
      # when home-manager users set `enable` explicitly.
      enable = cfg.enable == true || cfg.enable == null;
    in
    mkIf enable {
      assertions = quadletOptions.mkAssertions [ ] cfg;
      warnings = quadletOptions.mkWarnings [ ] cfg;

      virtualisation.podman.enable = true;
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
      systemd.services = mergeAttrsList (
        map (p: {
          ${p._serviceName} = {
            overrideStrategy = "asDropin";
            unitConfig.X-QuadletNixConfigHash = builtins.hashString "sha256" p._configText;
            # systemd recommends multi-user.target over default.target.
            # https://www.freedesktop.org/software/systemd/man/latest/systemd.special.html#default.target
            wantedBy = if p._autoStart then [ "multi-user.target" ] else [];
          };
        }) allObjects
      );

      systemd.timers.podman-auto-update = mkIf cfg.autoUpdate.enable {
        timerConfig.OnCalendar = [ "" cfg.autoUpdate.calendar ];
        wantedBy = [ "timers.target" ];
        overrideStrategy = "asDropin";
      };
    };
}
