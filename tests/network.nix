{ extraConfig, ... }:
{
  testConfig =
    { pkgs, config, ... }:
    {
      virtualisation.quadlet =
        let
          inherit (config.virtualisation.quadlet) networks;
        in
        {
          containers.nginx = {
            containerConfig = {
              image = "docker-archive:${pkgs.dockerTools.examples.nginx}";
              publishPorts = [ "8080:80" ];
              networks = [
                networks.foo.ref
                networks.bar.ref
              ];
            };
          }
          // extraConfig;
          networks.foo = {
            networkConfig.options.isolate = "true";
          }
          // extraConfig;
          networks.bar = { } // extraConfig;
        };
    };
  testScript = ''
    machine.wait_for_unit("nginx.service", user=systemd_user, timeout=30)
    assert "nginx" in machine.succeed("curl http://127.0.0.1:8080").lower()

    containers = get_containers()
    assert containers.keys() == {"nginx"}
    networks = get_networks()
    assert networks.keys() == {"foo", "bar", "podman"}
    assert set(containers["nginx"]["Networks"]) == {"foo", "bar"}
    assert networks["foo"]["options"]["isolate"] == "true"
    if podman_user is not None:
      assert not get_containers(user=None)
      assert get_networks(user=None).keys() == {"podman"}

    machine.stop_job("foo-network", user=systemd_user)
    machine.fail("curl http://127.0.0.1:8080")
    assert not get_containers()
    networks = get_networks()
    assert networks.keys() == {"bar", "podman"}

    machine.start_job("nginx", user=systemd_user)
    assert "nginx" in machine.succeed("curl http://127.0.0.1:8080").lower()
    containers = get_containers()
    assert containers.keys() == {"nginx"}
    networks = get_networks()
    assert networks.keys() == {"foo", "bar", "podman"}
  '';
}
