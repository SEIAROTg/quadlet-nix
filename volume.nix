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

  volumeOpts = {
    name = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "foo";
      description = "Volume name as in `podman volume create foo`";
      property = "VolumeName";
    };

    copy = quadletOptions.mkOption {
      type = types.nullOr types.bool;
      default = null;
      cli = "--opt copy";
      property = "Copy";
    };

    device = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "tmpfs";
      cli = "--opt device=...";
      property = "Device";
    };

    driver = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "image";
      cli = "--driver";
      property = "Driver";
    };

    globalArgs = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--log-level=debug" ];
      description = "Additional command line arguments to insert between `podman` and `volume create`";
      property = "GlobalArgs";
      encoders.scalar = encoders.scalar.quotedEscaped;
    };

    group = quadletOptions.mkOption {
      type = types.nullOr (
        types.oneOf [
          types.int
          types.str
        ]
      );
      default = null;
      example = 192;
      cli = "--opt group=...";
      property = "Group";
    };

    image = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "quay.io/centos/centos:latest";
      cli = "--opt image=...";
      property = "Image";
    };

    labels = quadletOptions.mkOption {
      type = types.oneOf [
        (types.listOf types.str)
        (types.attrsOf types.str)
      ];
      default = { };
      example = {
        foo = "bar";
      };
      cli = "--label";
      property = "Label";
      encoders.scalar = encoders.scalar.quotedEscaped;
    };

    modules = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/etc/nvd.conf" ];
      cli = "--module";
      property = "ContainersConfModule";
    };

    options = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      cli = "--opt o=...";
      property = "Options";
    };

    podmanArgs = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--driver=image" ];
      description = "Additional command line arguments to insert after `podman volume create`";
      property = "PodmanArgs";
      encoders.scalar = encoders.scalar.quotedEscaped;
    };

    type = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      cli = "--opt type=...";
      description = "Filesystem type of `device`";
      property = "Type";
    };

    user = quadletOptions.mkOption {
      type = types.nullOr (
        types.oneOf [
          types.int
          types.str
        ]
      );
      default = null;
      example = 123;
      cli = "--opt uid=...";
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
      quadlet = quadletUtils.configToProperties config.quadletConfig quadletOptions.quadletOpts;
      unitConfig = {
        Unit = {
          Description = "Podman volume ${name}";
        }
        // config.unitConfig;
        Volume = quadletUtils.configToProperties volumeConfig volumeOpts;
        Service = config.serviceConfig;
      }
      // (if quadlet == { } then { } else { Quadlet = quadlet; });
    in
    lib.pipe
      {
        _serviceName = "${name}-volume";
        _configText =
          if config.rawConfig != null then config.rawConfig else quadletUtils.unitConfigToText unitConfig;
        _autoStart = config.autoStart;
        _autoEscapeRequired = quadletUtils.autoEscapeRequired volumeConfig volumeOpts;
        ref = "${name}.volume";
      }
      [
        (quadletOptions.applyRootlessConfig config)
      ];
}
