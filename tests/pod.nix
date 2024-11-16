{ testers, quadletModule }: testers.runNixOSTest ({ ... }: {
  name = "pod";
  nodes.machine = { pkgs, config, ... }: {
    imports = [ quadletModule ];
    environment.systemPackages = [ pkgs.curl ];
    virtualisation.quadlet = let
     inherit (config.virtualisation.quadlet) pods;
    in {
      containers.nginx.containerConfig = {
        image = "docker-archive:${pkgs.dockerTools.examples.nginx}";
        pod = pods.foo.ref;
      };
      containers.redis.containerConfig = {
        image = "docker-archive:${pkgs.dockerTools.examples.redis}";
        pod = pods.foo.ref;
      };
      pods.foo.podConfig = {
        publishPorts = [ "8080:80" ];
      };
    };
  };
  testScript = ''
    import json

    machine.wait_for_unit("default.target")
    assert "nginx" in machine.succeed("curl http://127.0.0.1:8080").lower()

    containers = json.loads(machine.succeed("podman ps --format=json"))
    assert len(containers) == 3
    pods = json.loads(machine.succeed("podman pod ps --format=json"))
    assert len(pods) == 1
    assert set(c["Id"] for c in pods[0]["Containers"]) == {c["Id"] for c in containers}

    machine.stop_job("foo-pod")
    machine.fail("curl http://127.0.0.1:8080")
    containers = json.loads(machine.succeed("podman ps --format=json"))
    assert len(containers) == 0
    pods = json.loads(machine.succeed("podman pod ps --format=json"))
    assert len(pods) == 0

    machine.start_job("nginx")
    assert "nginx" in machine.succeed("curl http://127.0.0.1:8080").lower()
    machine.wait_for_unit("foo-pod.service", timeout=30)
    containers = json.loads(machine.succeed("podman ps --format=json"))
    print(containers)
    assert len(containers) == 2
    pods = json.loads(machine.succeed("podman pod ps --format=json"))
    assert len(pods) == 1

    machine.start_job("redis")
    assert "nginx" in machine.succeed("curl http://127.0.0.1:8080").lower()
    containers = json.loads(machine.succeed("podman ps --format=json"))
    assert len(containers) == 3
    pods = json.loads(machine.succeed("podman pod ps --format=json"))
    assert len(pods) == 1
  '';
})
