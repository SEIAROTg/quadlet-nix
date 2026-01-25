{ extraConfig, home, ... }: {
  testConfig = { pkgs, config, ... }: {
    virtualisation.quadlet = let
     inherit (config.virtualisation.quadlet) volumes;
    in {
      containers.write = {
        containerConfig = {
          image = "docker-archive:${pkgs.dockerTools.examples.bash}";
          entrypoint = "bash";
          exec = "-c 'echo 262c837a9160 > /mnt/foo/bar.txt'";
          volumes = [
            "${volumes.foo.ref}:/mnt/foo"
          ];
        };
        serviceConfig = {
          RemainAfterExit = true;
        };
      } // extraConfig;
      volumes.foo = {
        volumeConfig = {
          type = "bind";
          device = home;
        };
      } // extraConfig;
    };
  };
  testScript = ''
    machine.wait_for_unit("write.service", user=systemd_user, timeout=30)

    path = "${home}/bar.txt"
    machine.wait_for_file(path, timeout=10)
    assert machine.succeed(f"cat {path}").strip() == "262c837a9160"
  '';
}
