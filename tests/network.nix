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

    containers = list_containers(user=user)
    assert len(containers) == 1
    networks = list_networks(user=user)
    assert len(networks) == 3
    assert len(containers[0]["Networks"]) == 2
    if user is not None:
      assert not list_containers(user=None)
      assert len(list_networks(user=None)) == 1

    machine.stop_job("foo-network", user=user)
    machine.fail("curl http://127.0.0.1:8080")
    containers = list_containers(user=user)
    assert len(containers) == 0
    networks = list_networks(user=user)
    assert len(networks) == 2

    machine.start_job("nginx", user=user)
    assert "nginx" in machine.succeed("curl http://127.0.0.1:8080").lower()
    containers = list_containers(user=user)
    assert len(containers) == 1
    networks = list_networks(user=user)
    assert len(networks) == 3
  '';
}
