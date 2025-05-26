{ quadletUtils, quadletOptions }:
{
  config,
  name,
  lib,
  ...
}:
let
  inherit (lib) types;

  podOpts = {
    name = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "name";
      description = "--name";
      property = "PodName";
    };

    addHosts = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "hostname:192.168.10.11" ];
      description = "--add-host";
      property = "AddHost";
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

    dnsOptions = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "ndots:1" ];
      description = "--dns-option";
      property = "DNSOption";
    };

    dnsSearches = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "foo.com" ];
      description = "--dns-search";
      property = "DNSSearch";
    };

    gidMaps = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "0:10000:10" ];
      description = "--gidmap";
      property = "GIDMap";
      encoding = "quoted_unescaped";
    };

    globalArgs = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [  ];
      example = [ "--log-level=debug" ];
      description = "global args";
      property = "GlobalArgs";
      encoding = "quoted_escaped";
    };

    ip = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "192.5.0.1";
      description = "--ip";
      property = "IP";
    };

    ip6 = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "2001:db8::1";
      description = "--ip6";
      property = "IP6";
    };

    networks = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "host" ];
      description = "--network";
      property = "Network";
    };

    networkAliases = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "name" ];
      description = "--network-alias";
      property = "NetworkAlias";
    };

    podmanArgs = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--cpus=2" ];
      description = "Additional podman arguments";
      property = "PodmanArgs";
      encoding = "quoted_escaped";
    };

    publishPorts = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "50-59" ];
      description = "--publish";
      property = "PublishPort";
    };

    serviceName = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "service-name";
      description = "Instructs Quadlet to use the provided name.";
      property = "ServiceName";
    };

    subGIDMap = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "gtest";
      description = "--subgidname";
      property = "SubGIDMap";
    };

    subUIDMap = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "utest";
      description = "--subuidname";
      property = "SubUIDMap";
    };

    uidMaps = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "0:10000:10" ];
      description = "--uidmap";
      property = "UIDMap";
      encoding = "quoted_unescaped";
    };

    userns = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "keep-id:uid=200,gid=210";
      description = "--userns";
      property = "UserNS";
    };

    volumes = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/source:/dest" ];
      description = "--volume";
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
      quadlet = quadletUtils.configToProperties config.quadletConfig quadletUtils.quadletOpts;
      unitConfig = {
        Unit = {
          Description = "Podman pod ${name}";
        } // config.unitConfig;
        Pod = quadletUtils.configToProperties podConfig podOpts;
        Service = serviceConfigDefault // config.serviceConfig;
      } // (if quadlet == { } then { } else { Quadlet = quadlet; });
    in
    {
      _serviceName = "${name}-pod";
      _configText = if config.rawConfig != null
        then config.rawConfig
        else quadletUtils.unitConfigToText unitConfig;
      _autoEscapeRequired = quadletUtils.autoEscapeRequired podConfig podOpts;
      _autoStart = config.autoStart;
      ref = "${name}.pod";
    };
}
