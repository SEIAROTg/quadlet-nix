# this is a separate flake to so home-manager isn't made a compulsory input.

{
  description = "quadlet-nix tests";

  # inputs path to be set in --override-input
  inputs = {
    nixpkgs.url = "path:/dev/null";
    nixpkgs-2405.url = "github:NixOS/nixpkgs/nixos-24.05";

    quadlet-nix.url = "path:/dev/null";
    quadlet-nix.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "path:/dev/null";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    test-config.url = "path:/dev/null";
  };

  outputs =
    { test-config, nixpkgs, nixpkgs-2405, home-manager, quadlet-nix, ... }: let
      system = test-config.system;
      makeTestScript = { user, testScript }: { nodes, ... }: ''
        import json
        from typing import Any, Optional

        user = ${user}

        def _run_as_user(command: str, *, user: Optional[str]) -> str:
          if user is not None:
            command = f"sudo -u {user} -- {command}"
          return machine.succeed(command)

        def list_containers(*, user: Optional[str]) -> list[dict[str, Any]]:
          return json.loads(_run_as_user("podman ps --format=json", user=user))

        def list_networks(*, user: Optional[str]) -> list[dict[str, Any]]:
          return json.loads(_run_as_user("podman network ls --format=json", user=user))

        def list_pods(*, user: Optional[str]) -> list[dict[str, Any]]:
          return json.loads(_run_as_user("podman pod ls --format=json", user=user))

        def switch_to_specialisation(specialisation: str) -> str:
          return machine.succeed(f"${nodes.machine.system.build.toplevel}/specialisation/{specialisation}/bin/switch-to-configuration test")

        ${testScript}
      '';

      runRootfulTest = { name, testConfig, testScript, specialisation, pkgs }: pkgs.testers.runNixOSTest ({ ... }: {
        name = name + "-rootful";
        testScript = makeTestScript { user = "None"; inherit testScript; };

        nodes.machine = { pkgs, ... }@attrs: {
          imports = [
            quadlet-nix.nixosModules.quadlet
            testConfig
          ];
          environment.systemPackages = [ pkgs.curl ];
          specialisation = builtins.mapAttrs (name: value: { configuration = value; }) (specialisation attrs);
        };
      });

      runRootlessTest = { name, testConfig, testScript, specialisation, pkgs }: pkgs.testers.runNixOSTest ({ ... }: {
        name = name + "-rootless";
        testScript = makeTestScript { user = "\"alice\""; inherit testScript; };

        nodes.machine = { lib, pkgs, config, ... }@attrs: {
          imports = [
            quadlet-nix.nixosModules.quadlet
            home-manager.nixosModules.home-manager
          ];
          environment.systemPackages = [ pkgs.curl ];

          users.users.alice = {
            group = "alice";
            linger = true;
            autoSubUidGidRange = true;
            isNormalUser = true;
          };
          users.groups.alice = {};

          home-manager.users.alice = lib.mkDefault ({ ... }: {
            # sd-switch 0.5.0 doesn't start services on boot
            nixpkgs.overlays = [ (final: prev: { sd-switch = pkgs.sd-switch; }) ];
            imports = [
              quadlet-nix.homeManagerModules.quadlet
              testConfig
            ];
            systemd.user.startServices = "sd-switch";
            home.stateVersion = config.system.nixos.release;
          });

          specialisation = builtins.mapAttrs (name: value: {
            configuration = {
              home-manager.users.alice = ({ ... }: {
                imports = [
                  quadlet-nix.homeManagerModules.quadlet
                  testConfig
                  value
                ];
                systemd.user.startServices = "sd-switch";
                home.stateVersion = config.system.nixos.release;
              });
            };
          }) (specialisation attrs);
        };
      });

      genTest = pkgs: runTest: file: let
        name = pkgs.lib.removeSuffix ".nix" (builtins.baseNameOf file);
        value = ({ testConfig, testScript, specialisation ? _: { } }: runTest {
          inherit name pkgs testConfig testScript specialisation;
        }) (import file);
      in {
        name = value.config.name;
        inherit value;
      };

    in {
      checks = let
        pkgs = import nixpkgs { inherit system; };
        genRootfulTest = genTest pkgs runRootfulTest;
        sdSwitchBugAffected = let
          version = pkgs.sd-switch.version;
        in builtins.compareVersions version "0.5.0" >= 0;
        sdSwitchBugOverlay = final: prev: {
          sd-switch = (import nixpkgs-2405 { inherit system; }).sd-switch;
        };
        rootlessPkgs = if !sdSwitchBugAffected then pkgs else import nixpkgs {
          inherit system;
          overlays = [ sdSwitchBugOverlay ];
        };
        genRootlessTest = genTest rootlessPkgs runRootlessTest;
        tests = builtins.listToAttrs [
          (genRootfulTest ./basic.nix)
          (genRootlessTest ./basic.nix)
          (genRootfulTest ./container.nix)
          (genRootlessTest ./container.nix)
          (genRootfulTest ./network.nix)
          (genRootlessTest ./network.nix)
          (genRootfulTest ./pod.nix)
          (genRootlessTest ./pod.nix)
          (genRootfulTest ./switch.nix)
          (genRootlessTest ./switch.nix)
        ];
      in {
        "${system}" = tests;
      };
    };
}
