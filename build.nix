{ quadletUtils, quadletOptions }:
{
  config,
  name,
  lib,
  ...
}:
let
  inherit (lib) types;

  buildOpts = {
    annotations = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "XYZ" ];
      description = "--annotation";
      property = "Annotation";
      encoding = "quoted_escaped";
    };

    arch = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "aarch64";
      description = "--arch";
      property = "Arch";
    };

    authFile = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/etc/registry/auth.json";
      description = "--authfile";
      property = "AuthFile";
    };

    modules = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/etc/nvd.conf" ];
      description = "--module";
      property = "ContainersConfModule";
    };

    dns = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "192.168.55.1" ];
      description = "--dns";
      property = "DNS";
    };

    dnsSearch = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "foo.com" ];
      description = "--dns-search";
      property = "DNSSearch";
    };

    dnsOption = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "ndots:1" ];
      description = "--dns-option";
      property = "DNSOption";
    };

    environments = quadletOptions.mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        foo = "bar";
      };
      description = "--env";
      property = "Environment";
      encoding = "quoted_escaped";
    };

    file = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/path/to/Containerfile";
      description = "--file";
      property = "File";
    };

    forceRm = quadletOptions.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "--force-rm";
      property = "ForceRM";
    };

    globalArgs = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--log-level=debug" ];
      description = "global args";
      property = "GlobalArgs";
      encoding = "quoted_escaped";
    };

    addGroups = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "keep-groups" ];
      description = "--group-add";
      property = "GroupAdd";
    };

    tag = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "localhost/imagename";
      description = "--tag";
      property = "ImageTag";
    };

    labels = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "XYZ" ];
      description = "--label";
      property = "Label";
      encoding = "quoted_escaped";
    };

    networks = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "host" ];
      description = "--net";
      property = "Network";
    };

    podmanArgs = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--add-host foobar" ];
      description = "Additional podman arguments";
      property = "PodmanArgs";
      encoding = "quoted_escaped";
    };

    pull = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "never";
      description = "--pull";
      property = "Pull";
    };

    secrets = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "secret[,opt=opt …]" ];
      description = "--secret";
      property = "Secret";
      encoding = "quoted_escaped";
    };

    workdir = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "file";
      description = "Set WorkingDirectory of systemd unit file";
      property = "SetWorkingDirectory";
    };

    target = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "my-app";
      description = "--target";
      property = "Target";
    };

    tlsVerify = quadletOptions.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "--tls-verify";
      property = "TLSVerify";
    };

    variant = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "arm/v7";
      description = "--variant";
      property = "Variant";
    };

    volumes = quadletOptions.mkOption {
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
  options = quadletOptions.mkObjectOptions "container" {
    buildConfig = buildOpts;
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
