{ quadletUtils, quadletOptions }:
{
  config,
  name,
  lib,
  ...
}:
let
  inherit (lib) types;
  inherit (quadletUtils) encoders;

  kubeOpts = {
    autoUpdate = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "registry" ];
      cli = "--annotation \"io.containers.autoupdate=...\"";
      property = "AutoUpdate";
      encoders.scalar = encoders.scalar.quotedUnescaped;
    };

    configMaps = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/tmp/config.map" ];
      cli = "--configmap";
      property = "ConfigMap";
      encoders.scalar = encoders.scalar.quotedUnescaped;
    };

    modules = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/etc/nvd.conf" ];
      cli = "--module";
      property = "ContainersConfModule";
    };

    exitCodePropagation = quadletOptions.mkOption {
      type = types.nullOr (
        types.enum [
          "all"
          "any"
          "none"
        ]
      );
      default = null;
      example = "any";
      description = "Control how the main PID of the systemd service should exit";
      property = "ExitCodePropagation";
    };

    globalArgs = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--log-level=debug" ];
      description = "Additional command line arguments to insert between `podman` and `kube play`";
      property = "GlobalArgs";
      encoders.scalar = encoders.scalar.quotedEscaped;
    };

    kubeDownForce = quadletOptions.mkOption {
      type = types.nullOr types.bool;
      default = null;
      cli = "--force";
      description = "Remove all resources, including volumes, when calling `podman kube down`";
      property = "KubeDownForce";
    };

    logDriver = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "journald";
      cli = "--log-driver";
      property = "LogDriver";
    };

    networks = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "host" ];
      cli = "--network";
      property = "Network";
    };

    podmanArgs = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--annotation=key=value" ];
      description = "Additional command line arguments to insert after `podman kube play`";
      property = "PodmanArgs";
      encoders.scalar = encoders.scalar.quotedEscaped;
    };

    publishPorts = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "8080:80" ];
      cli = "--publish";
      property = "PublishPort";
    };

    setWorkingDirectory = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "yaml";
      description = "Sets WorkingDirectory of systemd unit file (`yaml` or `unit`)";
      property = "SetWorkingDirectory";
    };

    userNs = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "keep-id:uid=200,gid=210";
      cli = "--userns";
      property = "UserNS";
    };

    yaml = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/tmp/kube.yaml" ];
      description = "Path(s) to the Kubernetes YAML file. `podman kube play /tmp/kube.yaml`";
      property = "Yaml";
      encoders.scalar = encoders.scalar.quotedUnescaped;
    };
  };
in
{
  # No rootless support as we are not able to patch individual containers without config introspection.
  options = quadletOptions.mkObjectOptions "kube" {
    kubeConfig = kubeOpts;
  };

  config =
    let
      quadlet = quadletUtils.configToProperties config.quadletConfig quadletOptions.quadletOpts;
      unitConfig = {
        Unit = {
          Description = "Podman kube ${name}";
        }
        // config.unitConfig;
        Kube = quadletUtils.configToProperties config.kubeConfig kubeOpts;
        Service = config.serviceConfig;
      }
      // (if quadlet == { } then { } else { Quadlet = quadlet; });
    in
    {
      _serviceName = name;
      _configText =
        if config.rawConfig != null then config.rawConfig else quadletUtils.unitConfigToText unitConfig;
      _autoStart = config.autoStart;
      _autoEscapeRequired = quadletUtils.autoEscapeRequired config.kubeConfig kubeOpts;
      ref = "${name}.kube";
    };
}
