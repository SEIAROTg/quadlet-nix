{
  testConfig = { pkgs, ... }: {
    virtualisation.quadlet = {
      containers.good = {
        containerConfig = {
          image = "docker-archive:${pkgs.dockerTools.examples.redis}";
          healthCmd = "redis-cli ping || exit 1";
          healthRetries = 1;
        };
        serviceConfig.TimeoutStartSec = 60;
      };
      containers.bad = {
        containerConfig = {
          image = "docker-archive:${pkgs.dockerTools.examples.nginx}";
          healthCmd = "exit 1";
          healthRetries = 1;
        };
        serviceConfig.TimeoutStartSec = 60;
      };
    };
  };

  testScript = ''
    machine.wait_for_unit("default.target")
    machine.wait_for_unit("default.target", user=user)
    machine.wait_for_unit("good.service", user=user, timeout=30)
    machine.wait_for_unit("bad.service", user=user, timeout=30)
    machine.sleep(2)  # wait for health command cycles

    containers = list_containers(user=user)
    assert len(containers) == 2
    containers_by_name = {
      name: c
      for c in containers
      for name in c["Names"]
    }

    assert len(containers_by_name) == 2
    assert "(healthy)" in containers_by_name["good"]["Status"]
    assert "(unhealthy)" in containers_by_name["bad"]["Status"]
  '';
}
