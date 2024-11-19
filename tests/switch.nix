{
  testConfig = { lib, pkgs, ... }: let
    makeQuadletConfig = networks: {
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
    virtualisation.quadlet = lib.mkDefault (makeQuadletConfig [ "foo" ]);

    specialisation = {
      step1Add.configuration.virtualisation.quadlet = makeQuadletConfig [ "foo" "bar" ];
      step2Remove.configuration.virtualisation.quadlet = makeQuadletConfig [ "bar" ];
      step3AddRemove.configuration.virtualisation.quadlet = makeQuadletConfig [ "baz" ];
    };
  };
  testScript = ''
    def check(expected_networks: set[str]) -> None:
      assert "nginx" in machine.succeed("curl http://127.0.0.1:8080").lower()
      containers = json.loads(machine.succeed("podman ps --format=json"))
      assert len(containers) == 1
      networks = json.loads(machine.succeed("podman network ls --format=json"))
      network_names = {n["name"] for n in networks}
      assert network_names == expected_networks | {"podman"}
      assert set(containers[0]["Networks"]) == expected_networks

    machine.wait_for_unit("default.target")
    check({"foo"})

    switch_to_specialisation("step1Add")
    check({"foo", "bar"})

    switch_to_specialisation("step2Remove")
    check({"bar"})

    switch_to_specialisation("step3AddRemove")
    check({"baz"})
  '';
}
