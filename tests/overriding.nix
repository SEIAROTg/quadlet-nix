{ extraConfig, isHomeManager, ... }: {
  testConfig = { pkgs, lib, ... }: let
    execStartPre = "${pkgs.bash}/bin/bash -c 'echo ef1e835e0ae5 > /tmp/foo.txt'";
    nixosOverrides = {
      systemd.services.nginx.serviceConfig.ExecStartPre = execStartPre;
    };
    homeManagerOverrides = {
      systemd.user.services.nginx.Service.ExecStartPre = execStartPre;
    };
    overrides = if isHomeManager then homeManagerOverrides else nixosOverrides;
  in {
    virtualisation.quadlet = {
      containers.nginx = {
        containerConfig.image = "docker-archive:${pkgs.dockerTools.examples.nginx}";
        containerConfig.publishPorts = [ "8080:80" ];
        serviceConfig.TimeoutStartSec = "60";
      } // extraConfig;
    };
  } // overrides;
  testScript = ''
    machine.wait_for_unit("nginx.service", user=systemd_user, timeout=30)

    html = machine.succeed("curl http://127.0.0.1:8080")
    assert "nginx" in html.lower()
    assert machine.succeed("cat /tmp/foo.txt").strip() == "ef1e835e0ae5"
  '';
}
