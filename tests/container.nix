{
  testConfig = { pkgs, ... }: {
    virtualisation.quadlet = {
      containers.nginx = {
        containerConfig.image = "docker-archive:${pkgs.dockerTools.examples.nginx}";
        containerConfig.publishPorts = [ "8080:80" ];
        serviceConfig.TimeoutStartSec = "60";
      };
    };
  };
  testScript = ''
    machine.wait_for_unit("default.target")
    machine.wait_for_unit("default.target", user=user)
    machine.wait_for_unit("nginx.service", user=user, timeout=30)
    assert 'nginx' in machine.succeed("curl http://127.0.0.1:8080").lower()
    containers = get_containers(user=user)
    assert containers.keys() == {"nginx"}
    if user is not None:
      assert not get_containers(user=None)

    machine.stop_job("nginx", user=user)
    machine.fail("curl http://127.0.0.1:8080")
    assert not get_containers(user=user)

    machine.start_job("nginx", user=user)
    assert 'nginx' in machine.succeed("curl http://127.0.0.1:8080").lower()
    containers = get_containers(user=user)
    assert containers.keys() == {"nginx"}
  '';
}
