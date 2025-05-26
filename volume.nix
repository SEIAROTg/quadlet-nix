{ quadletUtils, quadletOptions }:
{
  config,
  name,
  lib,
  ...
}:
let
  inherit (lib) types;

  volumeOpts = {
    name = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "foo";
      description = "podman volume create foo";
      property = "VolumeName";
    };

    copy = quadletOptions.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "--opt copy";
      property = "Copy";
    };

    device = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "tmpfs";
      description = "--opt device=...";
      property = "Device";
    };

    driver = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "image";
      description = "--driver";
      property = "Driver";
    };

    globalArgs = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [  ];
      example = [ "--log-level=debug" ];
      description = "global args";
      property = "GlobalArgs";
      encoding = "quoted_escaped";
    };

    group = quadletOptions.mkOption {
      type = types.nullOr (types.oneOf [ types.int types.str ]);
      default = null;
      example = 192;
      description = "--opt group=...";
      property = "Group";
    };

    image = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "quay.io/centos/centos:latest";
      description = "--opt image=...";
      property = "Image";
    };

    labels = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "foo=bar" ];
      description = "--label";
      property = "Label";
      encoding = "quoted_escaped";
    };

    modules = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/etc/nvd.conf" ];
      description = "--module";
      property = "ContainersConfModule";
    };

    options = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "--opt o=...";
      property = "Options";
    };

    podmanArgs = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--driver=image" ];
      description = "Additional podman arguments";
      property = "PodmanArgs";
      encoding = "quoted_escaped";
    };

    type = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Filesystem type of Device";
      property = "Type";
    };

    user = quadletOptions.mkOption {
      type = types.nullOr (types.oneOf [ types.int types.str ]);
      default = null;
      example = 123;
      description = "--opt uid=...";
      property = "User";
    };
  };
in
{
  options = quadletOptions.mkObjectOptions "volume" {
    volumeConfig = volumeOpts;
  };

  config =
    let
      volumeName = if config.volumeConfig.name != null then config.volumeConfig.name else name;
      volumeConfig = config.volumeConfig // {
        name = volumeName;
      };
      quadlet = quadletUtils.configToProperties config.quadletConfig quadletUtils.quadletOpts;
      unitConfig = {
        Unit = {
          Description = "Podman volume ${name}";
        } // config.unitConfig;
        Volume = quadletUtils.configToProperties volumeConfig volumeOpts;
        Service = config.serviceConfig;
      } // (if quadlet == { } then { } else { Quadlet = quadlet; });
    in
    {
      _serviceName = "${name}-volume";
      _configText = if config.rawConfig != null
        then config.rawConfig
        else quadletUtils.unitConfigToText unitConfig;
      _autoStart = config.autoStart;
      _autoEscapeRequired = quadletUtils.autoEscapeRequired volumeConfig volumeOpts;
      ref = "${name}.volume";
    };
}
