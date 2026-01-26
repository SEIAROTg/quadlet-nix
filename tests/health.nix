{ extraConfig, ... }:
{
  testConfig =
    { pkgs, ... }:
    {
      virtualisation.quadlet = {
        containers.good = {
          containerConfig = {
            image = "docker-archive:${pkgs.dockerTools.examples.redis}";
            healthCmd = "redis-cli ping || exit 1";
            healthRetries = 1;
          };
          serviceConfig.TimeoutStartSec = 60;
        }
        // extraConfig;
        containers.bad = {
          containerConfig = {
            image = "docker-archive:${pkgs.dockerTools.examples.nginx}";
            healthCmd = "exit 1";
            healthRetries = 1;
          };
          serviceConfig.TimeoutStartSec = 60;
        }
        // extraConfig;
      };
    };

  testScript = ''
    machine.wait_for_unit("good.service", user=systemd_user, timeout=30)
    machine.wait_for_unit("bad.service", user=systemd_user, timeout=30)
    machine.sleep(2)  # wait for health command cycles

    containers = get_containers()
    assert containers.keys() == {"good", "bad"}
    assert "(healthy)" in containers["good"]["Status"]
    assert "(unhealthy)" in containers["bad"]["Status"]
  '';
}
