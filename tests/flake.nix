# this is a separate flake to so home-manager isn't made a compulsory input.

{
  description = "quadlet-nix tests";

  # inputs path to be set in --override-input
  inputs = {
    nixpkgs.url = "path:/dev/null";

    quadlet-nix.url = "path:/dev/null";
    quadlet-nix.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "path:/dev/null";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { nixpkgs, home-manager, quadlet-nix, ... }: let
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

      runRootfulTest = { name, testConfig, testScript, pkgs }: pkgs.testers.runNixOSTest ({ ... }: {
        name = name + "-rootful";
        testScript = makeTestScript { user = "None"; inherit testScript; };

        nodes.machine = { ... }: {
          imports = [
            quadlet-nix.nixosModules.quadlet
            testConfig
          ];
          environment.systemPackages = [ pkgs.curl ];
        };
      });

      runRootlessTest = { name, testConfig, testScript, pkgs }: pkgs.testers.runNixOSTest ({ ... }: {
        name = name + "-rootless";
        testScript = makeTestScript { user = "\"alice\""; inherit testScript; };

        nodes.machine = { config, ... }: {
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
            uid = 1000;
          };
          users.groups.alice = {};

          home-manager.users.alice = { ... }: {
            imports = [
              quadlet-nix.homeManagerModules.quadlet
              testConfig
            ];
            home.stateVersion = config.system.nixos.release;
          };
        };
      });

      genTest = pkgs: runTest: file: let
        name = pkgs.lib.removeSuffix ".nix" (builtins.baseNameOf file);
        value = ({ testConfig, testScript }: runTest {
          inherit name pkgs testConfig testScript;
        }) (import file);
      in {
        name = value.config.name;
        inherit value;
      };

    in {
      checks = let
        systems = [ "x86_64-linux" "aarch64-linux" ];
        genTests = system: let
          pkgs = import nixpkgs { inherit system; };
          genRootfulTest = genTest pkgs runRootfulTest;
          genRootlessTest = genTest pkgs runRootlessTest;
        in builtins.listToAttrs [
          (genRootfulTest ./basic.nix)
          (genRootlessTest ./basic.nix)
          (genRootfulTest ./container.nix)
          (genRootlessTest ./container.nix)
          (genRootfulTest ./network.nix)
          (genRootlessTest ./network.nix)
          (genRootfulTest ./pod.nix)
          (genRootlessTest ./pod.nix)
          (genRootfulTest ./switch.nix)
        ];
      in builtins.listToAttrs (map (system: { name = system; value = genTests system; }) systems);
    };
}
