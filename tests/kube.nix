{ extraConfig, ... }:
{
  testConfig =
    { pkgs, config, ... }:
    let
      inherit (config.virtualisation.quadlet) images;
      yaml = toString (
        pkgs.writeText "foo.yaml" ''
          apiVersion: v1
          kind: Pod
          metadata:
            name: foo
          spec:
            containers:
              - name: nginx
                image: nginx-container:latest
                ports:
                  - containerPort: 80
                    hostPort: 8080
              - name: redis
                image: redis:latest
        ''
      );
    in
    {
      virtualisation.quadlet = {
        images.nginx = {
          imageConfig = {
            image = "docker-archive:${pkgs.dockerTools.examples.nginx}";
            tag = "nginx-container:latest";
          };
        }
        // extraConfig;

        images.redis = {
          imageConfig = {
            image = "docker-archive:${pkgs.dockerTools.examples.redis}";
            tag = "redis:latest";
          };
        }
        // extraConfig;

        kubes.foo = {
          kubeConfig.yaml = [ yaml ];
          unitConfig = {
            Requires = [
              images.nginx.ref
              images.redis.ref
            ];
            After = [
              images.nginx.ref
              images.redis.ref
            ];
          };
        }
        // extraConfig;
      };
    };
  testScript = ''
    machine.wait_for_unit("foo.service", user=systemd_user, timeout=60)
    assert "nginx" in machine.succeed("curl http://127.0.0.1:8080").lower()

    containers = get_containers()
    assert len(containers) >= 2
    if podman_user is not None:
      assert not get_containers(user=None)

    machine.stop_job("foo", user=systemd_user)
    machine.fail("curl http://127.0.0.1:8080")
    assert not get_containers()
  '';
}
