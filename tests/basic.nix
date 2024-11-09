{ testers, quadletModule }: testers.runNixOSTest ({ ... }: {
  name = "basic";
  nodes.machine = { pkgs, ... }: {
    imports = [ quadletModule ];
    environment.systemPackages = [ pkgs.curl ];
    virtualisation.quadlet = {
      containers.nginx = {
        containerConfig.image = "docker-archive:${pkgs.dockerTools.examples.nginx}";
        containerConfig.publishPorts = [ "8080:80" ];
        serviceConfig.TimeoutStartSec = "60";
      };
    };
  };
  testScript = ''
    machine.wait_for_unit("default.target")
    html = machine.succeed("curl http://127.0.0.1:8080")
    assert "nginx" in html.lower()
  '';
})
