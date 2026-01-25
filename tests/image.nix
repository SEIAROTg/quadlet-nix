{ extraConfig, ... }: {
  testConfig = { pkgs, config, ... }: {
    virtualisation.quadlet = let
      inherit (config.virtualisation.quadlet) images;
    in {
      images.hello =
        let
          test-bash-image = pkgs.dockerTools.buildImage {
            name = "whatever.com/test-bash";
            tag = "latest";
            fromImage = pkgs.dockerTools.examples.bash;
          };
        in {
          imageConfig = {
            image = "docker-archive:${test-bash-image}";
            tag = "whatever.com/test-bash:latest";
          };
        } // extraConfig;

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
      } // extraConfig;
    };
  };

  testScript = ''
    machine.wait_for_unit("hello.service", user=systemd_user, timeout=30)

    assert machine.succeed("cat /tmp/result.txt").strip() == 'Success'
  '';
}
