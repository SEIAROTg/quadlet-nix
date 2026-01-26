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

  podOpts = {
    name = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "name";
      cli = "--name";
      property = "PodName";
    };

    addHosts = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "hostname:192.168.10.11" ];
      cli = "--add-host";
      property = "AddHost";
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

    dnsOptions = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "ndots:1" ];
      cli = "--dns-option";
      property = "DNSOption";
    };

    dnsSearches = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "foo.com" ];
      cli = "--dns-search";
      property = "DNSSearch";
    };

    gidMaps = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "0:10000:10" ];
      cli = "--gidmap";
      property = "GIDMap";
      encoders.scalar = encoders.scalar.quotedUnescaped;
    };

    globalArgs = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--log-level=debug" ];
      description = "Additional command line arguments to insert between `podman` and `pod create`";
      property = "GlobalArgs";
      encoders.scalar = encoders.scalar.quotedEscaped;
    };

    hostname = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "new-host-name";
      cli = "--hostname";
      property = "HostName";
    };

    ip = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "192.5.0.1";
      cli = "--ip";
      property = "IP";
    };

    ip6 = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "2001:db8::1";
      cli = "--ip6";
      property = "IP6";
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

    networks = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "host" ];
      cli = "--network";
      property = "Network";
    };

    networkAliases = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "name" ];
      cli = "--network-alias";
      property = "NetworkAlias";
    };

    podmanArgs = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--cpus=2" ];
      description = "Additional command line arguments to insert after `podman pod create`";
      property = "PodmanArgs";
      encoders.scalar = encoders.scalar.quotedEscaped;
    };

    publishPorts = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "50-59" ];
      cli = "--publish";
      property = "PublishPort";
    };

    # ServiceName not supported as custom service names can make quadlet-nix lost.

    shmSize = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "100m";
      cli = "--shm-size";
      property = "ShmSize";
    };

    subGIDMap = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "gtest";
      cli = "--subgidname";
      property = "SubGIDMap";
    };

    subUIDMap = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "utest";
      cli = "--subuidname";
      property = "SubUIDMap";
    };

    uidMaps = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "0:10000:10" ];
      cli = "--uidmap";
      property = "UIDMap";
      encoders.scalar = encoders.scalar.quotedUnescaped;
    };

    userns = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "keep-id:uid=200,gid=210";
      cli = "--userns";
      property = "UserNS";
    };

    volumes = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/source:/dest" ];
      cli = "--volume";
      property = "Volume";
    };
  };
in
{
  options = quadletOptions.mkObjectOptions "pod" {
    podConfig = podOpts;
  };

  config =
    let
      serviceConfigDefault = {
        Restart = "always";
        TimeoutStartSec = 900;
      };
      podName = if config.podConfig.name != null then config.podConfig.name else name;
      podConfig = config.podConfig // {
        name = podName;
      };
      quadlet = quadletUtils.configToProperties config.quadletConfig quadletOptions.quadletOpts;
      unitConfig = {
        Unit = {
          Description = "Podman pod ${name}";
        }
        // config.unitConfig;
        Pod = quadletUtils.configToProperties podConfig podOpts;
        Service = serviceConfigDefault // config.serviceConfig;
      }
      // (if quadlet == { } then { } else { Quadlet = quadlet; });
    in
    {
      _serviceName = "${name}-pod";
      _configText =
        if config.rawConfig != null then config.rawConfig else quadletUtils.unitConfigToText unitConfig;
      _autoEscapeRequired = quadletUtils.autoEscapeRequired podConfig podOpts;
      _autoStart = config.autoStart;
      ref = "${name}.pod";
    };
}
