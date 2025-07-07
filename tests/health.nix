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

    containers = get_containers(user=user)
    assert containers.keys() == {"good", "bad"}
    assert "(healthy)" in containers["good"]["Status"]
    assert "(unhealthy)" in containers["bad"]["Status"]
  '';
}
