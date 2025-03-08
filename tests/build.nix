{
  testConfig = { pkgs, config, ... }: {
    virtualisation.quadlet = let
      inherit (config.virtualisation.quadlet) builds;
    in {
      builds.hello = {
        buildConfig = {
          file = "${pkgs.writeText "Containerfile" ''
            FROM docker-archive:${pkgs.dockerTools.examples.bash}
            CMD bash -c 'echo "Success" > /output/result.txt'
          ''}";
        };
      };

      containers.hello = {
        containerConfig = {
          image = builds.hello.ref;
          volumes = [ "/tmp:/output" ];
        };
        serviceConfig = {
          RemainAfterExit = true;
        };
      };
    };
  };

  testScript = ''
    machine.wait_for_unit("default.target")
    machine.wait_for_unit("default.target", user=user)
    machine.wait_for_unit("hello.service", user=user, timeout=30)

    assert machine.succeed("cat /tmp/result.txt").strip() == 'Success'
  '';
}
