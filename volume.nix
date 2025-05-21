{ quadletUtils }:
{
  config,
  name,
  lib,
  ...
}:
let
  inherit (lib) types mkOption;

  volumeOpts = {
    name = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "foo";
      description = "podman volume create foo";
      property = "VolumeName";
    };

    copy = quadletUtils.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "--opt copy";
      property = "Copy";
    };

    device = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "tmpfs";
      description = "--opt device=...";
      property = "Device";
    };

    driver = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "image";
      description = "--driver";
      property = "Driver";
    };

    globalArgs = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--log-level=debug" ];
      description = "global args";
      property = "GlobalArgs";
      encoding = "quoted_escaped";
    };

    group = quadletUtils.mkOption {
      type = types.nullOr (
        types.oneOf [
          types.int
          types.str
        ]
      );
      default = null;
      example = 192;
      description = "--opt group=...";
      property = "Group";
    };

    image = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "quay.io/centos/centos:latest";
      description = "--opt image=...";
      property = "Image";
    };

    labels = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "foo=bar" ];
      description = "--label";
      property = "Label";
      encoding = "quoted_escaped";
    };

    modules = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/etc/nvd.conf" ];
      description = "--module";
      property = "ContainersConfModule";
    };

    options = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "--opt o=...";
      property = "Options";
    };

    podmanArgs = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--driver=image" ];
      description = "Additional podman arguments";
      property = "PodmanArgs";
      encoding = "quoted_escaped";
    };

    type = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Filesystem type of Device";
      property = "Type";
    };

    user = quadletUtils.mkOption {
      type = types.nullOr (
        types.oneOf [
          types.int
          types.str
        ]
      );
      default = null;
      example = 123;
      description = "--opt uid=...";
      property = "User";
    };
  };
in
{
  options = {
    volumeConfig = volumeOpts;

    quadletConfig = quadletUtils.quadletOpts;

    autoStart = mkOption {
      type = types.bool;
      default = true;
      example = true;
      description = "When enabled, the volume is automatically started on boot.";
    };

    unitConfig = mkOption {
      type = types.attrsOf quadletUtils.unitOption;
      default = { };
      description = "test";
    };

    serviceConfig = mkOption {
      type = types.attrsOf quadletUtils.unitOption;
      default = { };
      description = "test";
    };

    rawConfig = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "test";
    };

    _serviceName = mkOption { internal = true; };
    _configText = mkOption { internal = true; };
    _autoStart = mkOption { internal = true; };
    _autoEscapeRequired = mkOption { internal = true; };
    ref = mkOption {
      readOnly = true;
      description = "test";
    };
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
      _configText =
        if config.rawConfig != null then config.rawConfig else quadletUtils.unitConfigToText unitConfig;
      _autoStart = config.autoStart;
      _autoEscapeRequired = quadletUtils.autoEscapeRequired volumeConfig volumeOpts;
      ref = "${name}.volume";
    };
}
