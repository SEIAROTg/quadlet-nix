{ quadletUtils }:
{
  config,
  name,
  lib,
  ...
}:
let
  inherit (lib) types mkOption;

  buildOpts = {
    annotations = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "XYZ" ];
      description = "--annotation";
      property = "Annotation";
      encoding = "quoted_escaped";
    };

    arch = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "aarch64";
      description = "--arch";
      property = "Arch";
    };

    authFile = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/etc/registry/auth.json";
      description = "--authfile";
      property = "AuthFile";
    };

    modules = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/etc/nvd.conf" ];
      description = "--module";
      property = "ContainersConfModule";
    };

    dns = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "192.168.55.1" ];
      description = "--dns";
      property = "DNS";
    };

    dnsSearch = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "foo.com" ];
      description = "--dns-search";
      property = "DNSSearch";
    };

    dnsOption = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "ndots:1" ];
      description = "--dns-option";
      property = "DNSOption";
    };

    environments = quadletUtils.mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        foo = "bar";
      };
      description = "--env";
      property = "Environment";
      encoding = "quoted_escaped";
    };

    file = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/path/to/Containerfile";
      description = "--file";
      property = "File";
    };

    forceRm = quadletUtils.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "--force-rm";
      property = "ForceRM";
    };

    globalArgs = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--log-level=debug" ];
      description = "global args";
      property = "GlobalArgs";
      encoding = "quoted_escaped";
    };

    addGroups = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "keep-groups" ];
      description = "--group-add";
      property = "GroupAdd";
    };

    tag = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "localhost/imagename";
      description = "--tag";
      property = "ImageTag";
    };

    labels = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "XYZ" ];
      description = "--label";
      property = "Label";
      encoding = "quoted_escaped";
    };

    networks = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "host" ];
      description = "--net";
      property = "Network";
    };

    podmanArgs = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--add-host foobar" ];
      description = "Additional podman arguments";
      property = "PodmanArgs";
      encoding = "quoted_escaped";
    };

    pull = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "never";
      description = "--pull";
      property = "Pull";
    };

    secrets = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "secret[,opt=opt …]" ];
      description = "--secret";
      property = "Secret";
      encoding = "quoted_escaped";
    };

    workdir = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "file";
      description = "Set WorkingDirectory of systemd unit file";
      property = "SetWorkingDirectory";
    };

    target = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "my-app";
      description = "--target";
      property = "Target";
    };

    tlsVerify = quadletUtils.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "--tls-verify";
      property = "TLSVerify";
    };

    variant = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "arm/v7";
      description = "--variant";
      property = "Variant";
    };

    volumes = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/source:/dest" ];
      description = "--volume";
      property = "Volume";
    };
  };

  serviceConfigDefault = {
    TimeoutStartSec = 900;
  };
in
{
  options = {
    buildConfig = buildOpts;

    quadletConfig = quadletUtils.quadletOpts;

    autoStart = mkOption {
      type = types.bool;
      default = true;
      example = true;
      description = "When enabled, the build is automatically started on boot.";
    };

    unitConfig = mkOption {
      type = types.attrsOf quadletUtils.unitOption;
      default = { };
    };

    serviceConfig = mkOption {
      type = types.attrsOf quadletUtils.unitOption;
      default = { };
    };

    rawConfig = mkOption {
      type = types.nullOr types.str;
      default = null;
    };

    _serviceName = mkOption { internal = true; };
    _configText = mkOption { internal = true; };
    _autoStart = mkOption { internal = true; };
    _autoEscapeRequired = mkOption { internal = true; };
    ref = mkOption { readOnly = true; };
  };

  config =
    let
      buildTag = if config.buildConfig.tag != null then config.buildConfig.tag else "localhost/${name}";
      buildConfig = config.buildConfig // {
        tag = buildTag;
      };
      quadlet = quadletUtils.configToProperties config.quadletConfig quadletUtils.quadletOpts;
      unitConfig = {
        Unit = {
          Description = "Podman build ${name}";
        } // config.unitConfig;
        Build = quadletUtils.configToProperties buildConfig buildOpts;
        Service = serviceConfigDefault // config.serviceConfig;
      } // (if quadlet == { } then { } else { Quadlet = quadlet; });
    in
    {
      _serviceName = "${name}-build";
      _configText = if config.rawConfig != null
        then config.rawConfig
        else quadletUtils.unitConfigToText unitConfig;
      _autoStart = config.autoStart;
      _autoEscapeRequired = quadletUtils.autoEscapeRequired buildConfig buildOpts;
      ref = "${name}.build";
    };
}
