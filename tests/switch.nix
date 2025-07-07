let
  makeQuadletConfig = pkgs: networks: {
    containers.nginx.containerConfig = {
      image = "docker-archive:${pkgs.dockerTools.examples.nginx}";
      publishPorts = [ "8080:80" ];
      networks = map (x: "${x}.network") networks;
    };
    networks = builtins.listToAttrs (map (x: {
      name = x;
      value = { networkConfig.name = x; };
    }) networks);
  };
in {
  testConfig = { lib, pkgs, ... }: {
    virtualisation.quadlet = lib.mkDefault (makeQuadletConfig pkgs [ "foo" ]);
  };

  specialisation = { pkgs, ... }: {
    step1Add.virtualisation.quadlet = makeQuadletConfig pkgs [ "foo" "bar" ];
    step2Remove.virtualisation.quadlet = makeQuadletConfig  pkgs [ "bar" ];
    step3AddRemove.virtualisation.quadlet = makeQuadletConfig pkgs [ "baz" ];
  };

  testScript = ''
    def check(expected_networks: set[str]) -> None:
      assert "nginx" in machine.succeed("curl http://127.0.0.1:8080").lower()
      containers = get_containers(user=user)
      assert containers.keys() == {"nginx"}
      networks = get_networks(user=user)
      assert networks.keys() == expected_networks | {"podman"}
      assert set(containers["nginx"]["Networks"]) == expected_networks

    machine.wait_for_unit("default.target")
    machine.wait_for_unit("default.target", user=user)

    check({"foo"})

    switch_to_specialisation("step1Add")
    check({"foo", "bar"})

    switch_to_specialisation("step2Remove")
    check({"bar"})

    switch_to_specialisation("step3AddRemove")
    check({"baz"})
  '';
}
