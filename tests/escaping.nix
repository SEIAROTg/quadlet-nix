{ extraConfig, ... }:
{
  testConfig =
    { pkgs, ... }:
    {
      virtualisation.quadlet = {
        containers.write1 = {
          containerConfig = {
            image = "docker-archive:${pkgs.dockerTools.examples.bash}";
            # quotedUnescaped
            addCapabilities = [ "SYS_NICE" ];
            entrypoint = "bash";
            # quotedEscaped
            environments = {
              FOO = "aaa bbb $ccc \"ddd\n\n ";
              bar = "\"aaa\"";
              ONLY_SPACES = "aaa bbb";
            };
            # raw
            exec = "-c 'echo -n \"$FOO\" > /tmp/foo.txt; echo -n \"$bar\" > /tmp/bar.txt; echo -n \"$ONLY_SPACES\" > /tmp/only_spaces.txt'";
            volumes = [
              "/tmp:/tmp"
            ];
          };
          serviceConfig = {
            RemainAfterExit = true;
          };
        }
        // extraConfig;
        containers.write2 = {
          containerConfig = {
            image = "docker-archive:${pkgs.dockerTools.examples.bash}";
            environments = {
              BAZ = "aaa";
            };
            entrypoint = "bash";
            # oneLine
            exec = [
              "-c"
              "echo $@ $0 $BAZ > /tmp/baz.txt"
              "bbb"
              "ccc"
            ];
            volumes = [
              "/tmp:/tmp"
            ];
          };
          serviceConfig = {
            RemainAfterExit = true;
          };
        }
        // extraConfig;
        containers.write3 =
          let
            scriptName = "aaa bbb \n $ccc";
            scriptDir = toString (pkgs.writeTextDir scriptName "echo 8439b333258ba90e > /tmp/write3.txt");
          in
          {
            containerConfig = {
              image = "docker-archive:${pkgs.dockerTools.examples.bash}";
              entrypoint = [
                "bash"
                "/test/${scriptName}"
              ];
              volumes = [
                "/tmp:/tmp"
                "${scriptDir}:/test/"
              ];
            };
            serviceConfig = {
              RemainAfterExit = true;
            };
          }
          // extraConfig;
      };
    };
  testScript = ''
    machine.wait_for_unit("write1.service", user=systemd_user, timeout=30)
    machine.wait_for_unit("write2.service", user=systemd_user, timeout=30)
    machine.wait_for_unit("write3.service", user=systemd_user, timeout=30)

    machine.wait_for_file("/tmp/foo.txt", timeout=10)
    assert machine.succeed("cat /tmp/foo.txt") == 'aaa bbb $ccc "ddd\n\n '

    machine.wait_for_file("/tmp/bar.txt", timeout=10)
    assert machine.succeed("cat /tmp/bar.txt") == '"aaa"'

    machine.wait_for_file("/tmp/baz.txt", timeout=10)
    assert machine.succeed("cat /tmp/baz.txt") == 'ccc bbb aaa\n'

    machine.wait_for_file("/tmp/only_spaces.txt", timeout=10)
    assert machine.succeed("cat /tmp/only_spaces.txt") == 'aaa bbb'

    machine.wait_for_file("/tmp/write3.txt", timeout=10)
    assert machine.succeed("cat /tmp/write3.txt") == '8439b333258ba90e\n'
  '';

}
