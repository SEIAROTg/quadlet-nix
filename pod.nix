{ quadletUtils }:
{
  config,
  name,
  lib,
  ...
}:
let
  inherit (lib) types mkOption;

  podOpts = {
    name = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "name";
      description = "--name";
      property = "PodName";
    };

    addHosts = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "hostname:192.168.10.11" ];
      description = "--add-host";
      property = "AddHost";
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

    dnsOptions = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "ndots:1" ];
      description = "--dns-option";
      property = "DNSOption";
    };

    dnsSearches = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "foo.com" ];
      description = "--dns-search";
      property = "DNSSearch";
    };

    gidMaps = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "0:10000:10" ];
      description = "--gidmap";
      property = "GIDMap";
      encoding = "quoted_unescaped";
    };

    globalArgs = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--log-level=debug" ];
      description = "global args";
      property = "GlobalArgs";
      encoding = "quoted_escaped";
    };

    ip = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "192.5.0.1";
      description = "--ip";
      property = "IP";
    };

    ip6 = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "2001:db8::1";
      description = "--ip6";
      property = "IP6";
    };

    networks = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "host" ];
      description = "--network";
      property = "Network";
    };

    networkAliases = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "name" ];
      description = "--network-alias";
      property = "NetworkAlias";
    };

    podmanArgs = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--cpus=2" ];
      description = "Additional podman arguments";
      property = "PodmanArgs";
      encoding = "quoted_escaped";
    };

    publishPorts = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "50-59" ];
      description = "--publish";
      property = "PublishPort";
    };

    serviceName = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "service-name";
      description = "Instructs Quadlet to use the provided name.";
      property = "ServiceName";
    };

    subGIDMap = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "gtest";
      description = "--subgidname";
      property = "SubGIDMap";
    };

    subUIDMap = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "utest";
      description = "--subuidname";
      property = "SubUIDMap";
    };

    uidMaps = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "0:10000:10" ];
      description = "--uidmap";
      property = "UIDMap";
      encoding = "quoted_unescaped";
    };

    userns = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "keep-id:uid=200,gid=210";
      description = "--userns";
      property = "UserNS";
    };

    volumes = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/source:/dest" ];
      description = "--volume";
      property = "Volume";
    };
  };
in
{
  options = {
    podConfig = podOpts;

    quadletConfig = quadletUtils.quadletOpts;

    autoStart = mkOption {
      type = types.bool;
      default = true;
      example = true;
      description = "When enabled, the pod is automatically started on boot.";
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
      _configText =
        if config.rawConfig != null then config.rawConfig else quadletUtils.unitConfigToText unitConfig;
      _autoEscapeRequired = quadletUtils.autoEscapeRequired podConfig podOpts;
      _autoStart = config.autoStart;
      ref = "${name}.pod";
    };
}
