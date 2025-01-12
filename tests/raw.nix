{
  testConfig = { pkgs, ... }: {
    virtualisation.quadlet = {
      containers.nginx.rawConfig = ''
        [Container]
        Image=docker-archive:${pkgs.dockerTools.examples.nginx}
        PublishPort=8080:80
        [Service]
        TimeoutStartSec=60
      '';
    };
  };
  testScript = ''
    machine.wait_for_unit("default.target")
    machine.wait_for_unit("default.target", user=user)

    html = machine.succeed("curl http://127.0.0.1:8080")
    assert "nginx" in html.lower()
  '';
}
