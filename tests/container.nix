{ extraConfig, ... }: {
  testConfig = { pkgs, ... }: {
    virtualisation.quadlet = {
      containers.nginx = {
        containerConfig.image = "docker-archive:${pkgs.dockerTools.examples.nginx}";
        containerConfig.publishPorts = [ "8080:80" ];
        serviceConfig.TimeoutStartSec = "60";
      } // extraConfig;
    };
  };
  testScript = ''
    machine.wait_for_unit("nginx.service", user=systemd_user, timeout=30)
    assert 'nginx' in machine.succeed("curl http://127.0.0.1:8080").lower()
    containers = get_containers()
    assert containers.keys() == {"nginx"}
    if podman_user is not None:
      assert not get_containers(user=None)

    machine.stop_job("nginx", user=systemd_user)
    machine.fail("curl http://127.0.0.1:8080")
    assert not get_containers()

    machine.start_job("nginx", user=systemd_user)
    assert 'nginx' in machine.succeed("curl http://127.0.0.1:8080").lower()
    containers = get_containers()
    assert containers.keys() == {"nginx"}
  '';
}
