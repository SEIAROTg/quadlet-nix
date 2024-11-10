{ testers, quadletModule }: testers.runNixOSTest ({ ... }: {
  name = "container";
  nodes.machine = { pkgs, ... }: {
    imports = [ quadletModule ];
    environment.systemPackages = [ pkgs.curl ];
    virtualisation.quadlet = {
      containers.nginx = {
        containerConfig.image = "docker-archive:${pkgs.dockerTools.examples.nginx}";
        containerConfig.publishPorts = [ "8080:80" ];
        serviceConfig.TimeoutStartSec = "60";
      };
    };
  };
  testScript = ''
    import json

    machine.wait_for_unit("default.target")
    assert 'nginx' in machine.succeed("curl http://127.0.0.1:8080").lower()
    containers = json.loads(machine.succeed("podman ps --format=json"))
    assert len(containers) == 1

    machine.stop_job("nginx")
    machine.fail("curl http://127.0.0.1:8080")
    containers = json.loads(machine.succeed("podman ps --format=json"))
    assert len(containers) == 0

    machine.start_job("nginx")
    assert 'nginx' in machine.succeed("curl http://127.0.0.1:8080").lower()
    containers = json.loads(machine.succeed("podman ps --format=json"))
    assert len(containers) == 1
  '';
})
