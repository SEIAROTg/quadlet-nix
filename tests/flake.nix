# this is a separate flake to so home-manager isn't made a compulsory input.

{
  description = "quadlet-nix tests";

  # inputs path to be set in --override-input
  inputs = {
    nixpkgs.url = "path:/dev/null";

    quadlet-nix.url = "path:..";

    home-manager.url = "path:/dev/null";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    test-config.url = "path:/dev/null";
  };

  outputs =
    { test-config, nixpkgs, home-manager, quadlet-nix, ... }: let
      system = test-config.system;
      makeTestScript = { user, testScript }: { nodes, ... }: ''
        import json
        from typing import Any, Optional

        user = ${user}

        def _run_as_user(command: str, *, user: Optional[str]) -> str:
          if user is not None:
            command = f"sudo -u {user} -- {command}"
          return machine.succeed(command)

        def get_containers(*, user: Optional[str]) -> dict[str, dict[str, Any]]:
          containers = json.loads(_run_as_user("podman ps --format=json", user=user))
          return {name: container for container in containers for name in container["Names"]}

        def get_networks(*, user: Optional[str]) -> dict[str, dict[str, Any]]:
          networks = json.loads(_run_as_user("podman network ls --format=json", user=user))
          return {network["name"]: network for network in networks}

        def get_pods(*, user: Optional[str]) -> dict[str, dict[str, Any]]:
          pods = json.loads(_run_as_user("podman pod ls --format=json", user=user))
          return {pod["Name"]: pod for pod in pods}

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

        nodes.machine = { lib, pkgs, ... }@attrs: {
          imports = [
            quadlet-nix.nixosModules.quadlet
            home-manager.nixosModules.home-manager
          ];
          virtualisation.quadlet.enable = true;
          environment.systemPackages = [ pkgs.curl ];

          # brings up network-online.target
          systemd.targets.test-network = {
            wants = [ "network-online.target" ];
            wantedBy = [ "multi-user.target" ];
          };

          users.users.alice = {
            group = "alice";
            linger = true;
            autoSubUidGidRange = true;
            isNormalUser = true;
          };
          users.groups.alice = {};

          home-manager.users.alice = lib.mkDefault ({ config, ... }: {
            imports = [
              quadlet-nix.homeManagerModules.quadlet
              testConfig
            ];
            home.stateVersion = config.home.version.release;
          });

          specialisation = builtins.mapAttrs (name: value: {
            configuration = {
              home-manager.users.alice = ({ config, ... }: {
                imports = [
                  quadlet-nix.homeManagerModules.quadlet
                  testConfig
                  value
                ];
                home.stateVersion = config.home.version.release;
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
        genRootlessTest = genTest pkgs runRootlessTest;
        tests = builtins.listToAttrs [
          (genRootfulTest ./basic.nix)
          (genRootlessTest ./basic.nix)
          (genRootfulTest ./build.nix)
          (genRootlessTest ./build.nix)
          (genRootfulTest ./container.nix)
          (genRootlessTest ./container.nix)
          (genRootfulTest ./image.nix)
          (genRootlessTest ./image.nix)
          (genRootfulTest ./network.nix)
          (genRootlessTest ./network.nix)
          (genRootfulTest ./pod.nix)
          (genRootlessTest ./pod.nix)
          (genRootfulTest ./volume.nix)
          (genRootlessTest ./volume.nix)
          (genRootfulTest ./switch.nix)
          (genRootlessTest ./switch.nix)
          (genRootfulTest ./raw.nix)
          (genRootlessTest ./raw.nix)
          (genRootfulTest ./health.nix)
          (genRootlessTest ./health.nix)
          (genRootfulTest ./escaping.nix)
          (genRootlessTest ./escaping.nix)
        ];
      in {
        "${system}" = tests;
      };
    };
}
