{
  testConfig =
    { pkgs, config, ... }:
    {
      virtualisation.quadlet =
        let
          inherit (config.virtualisation.quadlet) images;
        in
        {
          images.hello =
            let
              test-bash-image = pkgs.dockerTools.buildImage {
                name = "whatever.com/test-bash";
                tag = "latest";
                fromImage = pkgs.dockerTools.examples.bash;
              };
            in
            {
              imageConfig = {
                image = "docker-archive:${test-bash-image}";
                tag = "whatever.com/test-bash:latest";
              };
            };

          containers.hello = {
            containerConfig = {
              image = images.hello.ref;
              volumes = [ "/tmp:/output" ];
              entrypoint = "bash";
              exec = [
                "-c"
                "echo \"Success\" > /output/result.txt"
              ];
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
