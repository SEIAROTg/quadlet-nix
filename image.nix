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

  imageOpts = {
    allTags = quadletOptions.mkOption {
      type = types.nullOr types.bool;
      default = null;
      cli = "--all-tags";
      property = "AllTags";
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

    certDir = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/etc/registry/certs";
      cli = "--cert-dir";
      property = "CertDir";
    };

    modules = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/etc/nvd.conf" ];
      cli = "--module";
      property = "ContainersConfModule";
    };

    creds = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "myname:mypassword";
      cli = "--creds";
      property = "Creds";
    };

    decryptionKey = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/etc/registry.key";
      cli = "--decryption-key";
      property = "DecryptionKey";
    };

    globalArgs = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--log-level=debug" ];
      description = "Additional command line arguments to insert between `podman` and `pull`";
      property = "GlobalArgs";
      encoders.scalar = encoders.scalar.quotedEscaped;
    };

    image = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "docker.io/library/nginx:latest";
      description = "Image specification";
      property = "Image";
    };

    tag = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "localhost/imagename";
      description = "FQIN of the referenced Image. Only meaningful when source is a file or directory archive. Used when resolving .image references.";
      property = "ImageTag";
    };

    os = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "windows";
      cli = "--os";
      property = "OS";
    };

    podmanArgs = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--add-host foobar" ];
      description = "Additional command line arguments to insert after `podman pull`";
      property = "PodmanArgs";
      encoders.scalar = encoders.scalar.quotedEscaped;
    };

    policy = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "always";
      cli = "--policy";
      property = "Policy";
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
  };

  serviceConfigDefault = {
    TimeoutStartSec = 900;
  };
in
{
  options = quadletOptions.mkObjectOptions "image" {
    imageConfig = imageOpts;
  };

  config =
    let
      imageTag = if config.imageConfig.tag != null then config.imageConfig.tag else "localhost/${name}";
      imageConfig = config.imageConfig // {
        tag = imageTag;
      };
      quadlet = quadletUtils.configToProperties config.quadletConfig quadletOptions.quadletOpts;
      unitConfig = {
        Unit = {
          Description = "Podman image ${name}";
        } // config.unitConfig;
        Image = quadletUtils.configToProperties imageConfig imageOpts;
        Service = serviceConfigDefault // config.serviceConfig;
      } // (if quadlet == { } then { } else { Quadlet = quadlet; });
    in
    {
      _serviceName = "${name}-image";
      _configText = if config.rawConfig != null
        then config.rawConfig
        else quadletUtils.unitConfigToText unitConfig;
      _autoStart = config.autoStart;
      _autoEscapeRequired = quadletUtils.autoEscapeRequired imageConfig imageOpts;
      ref = "${name}.image";
    };
}
