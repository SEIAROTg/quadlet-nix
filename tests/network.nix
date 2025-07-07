{
  testConfig = { pkgs, config, ... }: {
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
    machine.wait_for_unit("default.target")
    machine.wait_for_unit("default.target", user=user)
    machine.wait_for_unit("nginx.service", user=user, timeout=30)
    assert "nginx" in machine.succeed("curl http://127.0.0.1:8080").lower()

    containers = get_containers(user=user)
    assert containers.keys() == {"nginx"}
    networks = get_networks(user=user)
    assert networks.keys() == {"foo", "bar", "podman"}
    assert set(containers["nginx"]["Networks"]) == {"foo", "bar"}
    if user is not None:
      assert not get_containers(user=None)
      assert get_networks(user=None).keys() == {"podman"}

    machine.stop_job("foo-network", user=user)
    machine.fail("curl http://127.0.0.1:8080")
    assert not get_containers(user=user)
    networks = get_networks(user=user)
    assert networks.keys() == {"bar", "podman"}

    machine.start_job("nginx", user=user)
    assert "nginx" in machine.succeed("curl http://127.0.0.1:8080").lower()
    containers = get_containers(user=user)
    assert containers.keys() == {"nginx"}
    networks = get_networks(user=user)
    assert networks.keys() == {"foo", "bar", "podman"}
  '';
}
