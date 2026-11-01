{ extraConfig, ... }:
{
  testConfig =
    { pkgs, config, ... }:
    {
      virtualisation.quadlet =
        let
          inherit (config.virtualisation.quadlet) builds;
          buildContext = pkgs.runCommand "build-context" { } ''
            mkdir -p "$out"
            cp ${pkgs.dockerTools.examples.bash} "$out/base.tar.gz"
          '';
        in
        {
          builds.hello = {
            buildConfig = {
              file = "${pkgs.writeText "Containerfile" ''
                FROM docker-archive:base.tar.gz
                CMD bash -c 'echo "Success" > /output/result.txt'
              ''}";
              workdir = "${buildContext}";
            };
            # for compatibility with podman<6 which resolves base image relative to process workdir.
            # TODO: remove once we stop running tests for podman<6.
            serviceConfig.WorkingDirectory = "${buildContext}";
          }
          // extraConfig;

          containers.hello = {
            containerConfig = {
              image = builds.hello.ref;
              volumes = [ "/tmp:/output" ];
            };
            serviceConfig = {
              RemainAfterExit = true;
            };
          }
          // extraConfig;
        };
    };

  testScript = ''
    machine.wait_for_unit("hello.service", user=systemd_user, timeout=30)

    assert machine.succeed("cat /tmp/result.txt").strip() == 'Success'
  '';
}
