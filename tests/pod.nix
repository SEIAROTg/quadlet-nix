{
  testConfig =
    { pkgs, config, ... }:
    {
      virtualisation.quadlet =
        let
          inherit (config.virtualisation.quadlet) pods;
        in
        {
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
    machine.wait_for_unit("nginx.service", user=user, timeout=30)
    machine.wait_for_unit("redis.service", user=user, timeout=30)
    assert "nginx" in machine.succeed("curl http://127.0.0.1:8080").lower()

    containers = get_containers(user=user)
    assert len(containers) == 3
    assert containers.keys() >= {"nginx", "redis"}
    pods = get_pods(user=user)
    assert pods.keys() == {"foo"}
    assert set(c["Id"] for c in pods["foo"]["Containers"]) == {c["Id"] for c in containers.values()}
    if user is not None:
      assert not get_containers(user=None)
      assert not get_pods(user=None)

    machine.stop_job("foo-pod", user=user)
    machine.fail("curl http://127.0.0.1:8080")
    assert not get_containers(user=user)
    assert not get_pods(user=user)

    machine.start_job("nginx", user=user)
    assert "nginx" in machine.succeed("curl http://127.0.0.1:8080").lower()
    machine.wait_for_unit("foo-pod.service", user=user, timeout=30)
    machine.wait_for_unit("nginx.service", user=user, timeout=30)
    machine.wait_for_unit("redis.service", user=user, timeout=30)
    containers = get_containers(user=user)
    assert len(containers) == 3
    assert containers.keys() >= {"nginx", "redis"}
    pods = get_pods(user=user)
    assert pods.keys() == {"foo"}
  '';
}
