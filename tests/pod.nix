{
  testConfig = { pkgs, config, ... }: {
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
    machine.wait_for_unit("default.target")
    machine.wait_for_unit("default.target", user=user)
    assert "nginx" in machine.succeed("curl http://127.0.0.1:8080").lower()

    containers = list_containers(user=user)
    assert len(containers) == 3
    pods = list_pods(user=user)
    assert len(pods) == 1
    assert set(c["Id"] for c in pods[0]["Containers"]) == {c["Id"] for c in containers}
    if user is not None:
      assert not list_containers(user=None)
      assert not list_pods(user=None)

    machine.stop_job("foo-pod", user=user)
    machine.fail("curl http://127.0.0.1:8080")
    containers = list_containers(user=user)
    assert len(containers) == 0
    pods = list_pods(user=user)
    assert len(pods) == 0

    machine.start_job("nginx", user=user)
    assert "nginx" in machine.succeed("curl http://127.0.0.1:8080").lower()
    machine.wait_for_unit("foo-pod.service", user=user, timeout=30)
    containers = list_containers(user=user)
    print(containers)
    assert len(containers) == 2
    pods = list_pods(user=user)
    assert len(pods) == 1

    machine.start_job("redis", user=user)
    assert "nginx" in machine.succeed("curl http://127.0.0.1:8080").lower()
    containers = list_containers(user=user)
    assert len(containers) == 3
    pods = list_pods(user=user)
    assert len(pods) == 1
  '';
}
