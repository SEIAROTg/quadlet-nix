{
  testConfig = { pkgs, ... }: {
    virtualisation.quadlet = {
      autoEscape = true;
      containers.write1 = {
        containerConfig = {
          image = "docker-archive:${pkgs.dockerTools.examples.bash}";
          # quoted_unescaped
          addCapabilities = [ "SYS_NICE" ];
          entrypoint = "bash";
          # quoted_escaped
          environments = {
            FOO = "aaa bbb $ccc \"ddd\n\n ";
            bar = "\"aaa\"";
          };
          # quoted_escaped_singleline
          exec = "-c 'echo -n \"$FOO\" > /tmp/foo.txt; echo -n \"$bar\" > /tmp/bar.txt'";
          volumes = [
            "/tmp:/tmp"
          ];
        };
        serviceConfig = {
          RemainAfterExit = true;
        };
      };
      containers.write2 = {
        containerConfig = {
          image = "docker-archive:${pkgs.dockerTools.examples.bash}";
          environments = {
            BAZ = "aaa";
          };
          entrypoint = "bash";
          # quoted_escaped_singleline
          exec = [ "-c" "echo $@ $0 $BAZ > /tmp/baz.txt" "bbb" "ccc" ];
          volumes = [
            "/tmp:/tmp"
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

    machine.wait_for_unit("write1.service", user=user, timeout=30)
    machine.wait_for_unit("write2.service", user=user, timeout=30)

    machine.wait_for_file("/tmp/foo.txt", timeout=10)
    assert machine.succeed("cat /tmp/foo.txt") == 'aaa bbb $ccc "ddd\n\n '

    machine.wait_for_file("/tmp/bar.txt", timeout=10)
    assert machine.succeed("cat /tmp/bar.txt") == '"aaa"'

    machine.wait_for_file("/tmp/baz.txt", timeout=10)
    assert machine.succeed("cat /tmp/baz.txt") == 'ccc bbb aaa\n'
  '';

}
