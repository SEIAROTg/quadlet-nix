{ testers, quadletModule }: testers.runNixOSTest ({ ... }: {
  name = "network";
  nodes.machine = { pkgs, config, ... }: {
    imports = [ quadletModule ];
    environment.systemPackages = [ pkgs.curl ];
    virtualisation.quadlet = let
     inherit (config.virtualisation.quadlet) networks;
    in {
      containers.nginx.containerConfig = {
        image = "docker-archive:${pkgs.dockerTools.examples.nginx}";
        publishPorts = [ "8080:80" ];
        networks = [ networks.foo.ref networks.bar.ref ];
      };
      networks.foo = { };
      networks.bar = { };
    };
  };
  testScript = ''
    import json

    machine.wait_for_unit("default.target")
    assert "nginx" in machine.succeed("curl http://127.0.0.1:8080").lower()

    containers = json.loads(machine.succeed("podman ps --format=json"))
    assert len(containers) == 1
    networks = json.loads(machine.succeed("podman network ls --format=json"))
    assert len(networks) == 3
    assert len(containers[0]["Networks"]) == 2

    machine.stop_job("foo-network")
    machine.fail("curl http://127.0.0.1:8080")
    containers = json.loads(machine.succeed("podman ps --format=json"))
    assert len(containers) == 0
    networks = json.loads(machine.succeed("podman network ls --format=json"))
    assert len(networks) == 2

    machine.start_job("nginx")
    assert "nginx" in machine.succeed("curl http://127.0.0.1:8080").lower()
    containers = json.loads(machine.succeed("podman ps --format=json"))
    assert len(containers) == 1
    networks = json.loads(machine.succeed("podman network ls --format=json"))
    assert len(networks) == 3
  '';
})
