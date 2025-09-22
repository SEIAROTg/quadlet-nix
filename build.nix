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

  buildOpts = {
    annotations = quadletOptions.mkOption {
      type = types.oneOf [ (types.listOf types.str) (types.attrsOf types.str) ];
      default = { };
      example = {
        annotation = "value";
      };
      cli = "--annotation";
      property = "Annotation";
      encoders.scalar = encoders.scalar.quotedEscaped;
    };

    arch = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "aarch64";
      cli = "--arch";
      property = "Arch";
    };

    authFile = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/etc/registry/auth.json";
      cli = "--authfile";
      property = "AuthFile";
    };

    modules = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/etc/nvd.conf" ];
      cli = "--module";
      property = "ContainersConfModule";
    };

    dns = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "192.168.55.1" ];
      cli = "--dns";
      property = "DNS";
    };

    dnsSearch = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "foo.com" ];
      cli = "--dns-search";
      property = "DNSSearch";
    };

    dnsOption = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "ndots:1" ];
      cli = "--dns-option";
      property = "DNSOption";
    };

    environments = quadletOptions.mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        foo = "bar";
      };
      cli = "--env";
      property = "Environment";
      encoders.scalar = encoders.scalar.quotedEscaped;
    };

    file = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/path/to/Containerfile";
      cli = "--file";
      property = "File";
    };

    forceRm = quadletOptions.mkOption {
      type = types.nullOr types.bool;
      default = null;
      cli = "--force-rm";
      property = "ForceRM";
    };

    globalArgs = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--log-level=debug" ];
      description = "Additional command line arguments to insert between `podman` and `build`";
      property = "GlobalArgs";
      encoders.scalar = encoders.scalar.quotedEscaped;
    };

    addGroups = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "keep-groups" ];
      cli = "--group-add";
      property = "GroupAdd";
    };

    tag = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "localhost/imagename";
      cli = "--tag";
      property = "ImageTag";
    };

    labels = quadletOptions.mkOption {
      type = types.oneOf [ (types.listOf types.str) (types.attrsOf types.str) ];
      default = { };
      example = {
        foo = "bar";
      };
      cli = "--label";
      property = "Label";
      encoders.scalar = encoders.scalar.quotedEscaped;
    };

    networks = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "host" ];
      cli = "--net";
      property = "Network";
    };

    podmanArgs = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--add-host foobar" ];
      description = "Additional command line arguments to insert after `podman build`";
      property = "PodmanArgs";
      encoders.scalar = encoders.scalar.quotedEscaped;
    };

    pull = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "never";
      cli = "--pull";
      property = "Pull";
    };

    retry = quadletOptions.mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 5;
      cli = "--retry";
      property = "Retry";
    };

    retryDelay = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "5s";
      cli = "--retry-delay";
      property = "RetryDelay";
    };

    secrets = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "secret[,opt=opt …]" ];
      cli = "--secret";
      property = "Secret";
      encoders.scalar = encoders.scalar.quotedEscaped;
    };

    workdir = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "file";
      description = "Sets WorkingDirectory of systemd unit file";
      property = "SetWorkingDirectory";
    };

    target = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "my-app";
      cli = "--target";
      property = "Target";
    };

    tlsVerify = quadletOptions.mkOption {
      type = types.nullOr types.bool;
      default = null;
      cli = "--tls-verify";
      property = "TLSVerify";
    };

    variant = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "arm/v7";
      cli = "--variant";
      property = "Variant";
    };

    volumes = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/source:/dest" ];
      cli = "--volume";
      property = "Volume";
    };
  };

  serviceConfigDefault = {
    TimeoutStartSec = 900;
  };
in
{
  options = quadletOptions.mkObjectOptions "build" {
    buildConfig = buildOpts;
  };

  config =
    let
      buildTag = if config.buildConfig.tag != null then config.buildConfig.tag else "localhost/${name}";
      buildConfig = config.buildConfig // {
        tag = buildTag;
      };
      quadlet = quadletUtils.configToProperties config.quadletConfig quadletOptions.quadletOpts;
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
