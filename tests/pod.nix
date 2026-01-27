{ extraConfig, ... }:
{
  testConfig =
    { pkgs, config, ... }:
    {
      virtualisation.quadlet =
        let
          inherit (config.virtualisation.quadlet) pods;
        in
        {
          containers.nginx = {
            containerConfig = {
              image = "docker-archive:${pkgs.dockerTools.examples.nginx}";
              pod = pods.foo.ref;
            };
          }
          // extraConfig;
          containers.redis = {
            containerConfig = {
              image = "docker-archive:${pkgs.dockerTools.examples.redis}";
              pod = pods.foo.ref;
            };
          }
          // extraConfig;
          pods.foo = {
            podConfig = {
              publishPorts = [ "8080:80" ];
            };
          }
          // extraConfig;
        };
    };
  testScript = ''
    machine.wait_for_unit("nginx.service", user=systemd_user, timeout=30)
    machine.wait_for_unit("redis.service", user=systemd_user, timeout=30)
    assert "nginx" in machine.succeed("curl http://127.0.0.1:8080").lower()

    containers = get_containers()
    assert len(containers) == 3
    assert containers.keys() >= {"nginx", "redis"}
    pods = get_pods()
    assert pods.keys() == {"foo"}
    assert set(c["Id"] for c in pods["foo"]["Containers"]) == {c["Id"] for c in containers.values()}
    if podman_user is not None:
      assert not get_containers(user=None)
      assert not get_pods(user=None)

    machine.stop_job("foo-pod", user=systemd_user)
    machine.fail("curl http://127.0.0.1:8080")
    assert not get_containers()
    assert not get_pods()

    machine.start_job("nginx", user=systemd_user)
    assert "nginx" in machine.succeed("curl http://127.0.0.1:8080").lower()
    machine.wait_for_unit("foo-pod.service", user=systemd_user, timeout=30)
    machine.wait_for_unit("nginx.service", user=systemd_user, timeout=30)
    machine.wait_for_unit("redis.service", user=systemd_user, timeout=30)
    containers = get_containers()
    assert len(containers) == 3
    assert containers.keys() >= {"nginx", "redis"}
    pods = get_pods()
    assert pods.keys() == {"foo"}

    run_as("podman pod stop foo", user=podman_user)
    wait_for_unit_inactive("foo-pod.service", user=systemd_user, timeout=10)
    wait_for_unit_inactive("nginx.service", user=systemd_user, timeout=10)
    wait_for_unit_inactive("redis.service", user=systemd_user, timeout=10)
  '';
}
