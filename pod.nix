{ quadletUtils }:
{
  config,
  name,
  lib,
  ...
}:
with lib;
let
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
    };

    # Not recommended to use by upstream:
    # globalArgs = quadletUtils.mkOption {
    #   type = types.listOf types.str;
    #   default = [ ];
    #   example = [ "--log-level=debug" ];
    #   description = "";
    #   property = "GlobalArgs";
    # };

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
      example = [ ];
      description = "--volume";
      property = "Volume";
    };
  };
in
{
  options = {
    podConfig = podOpts;

    autoStart = mkOption {
      type = types.bool;
      default = true;
      example = true;
      description = "When enabled, the pod is automatically started on boot.";
    };

    unitConfig = mkOption {
      type = types.attrs;
      default = { };
    };

    serviceConfig = mkOption {
      type = types.attrs;
      default = { };
    };

    _name = mkOption { internal = true; };
    _configName = mkOption { internal = true; };
    _unitName = mkOption { internal = true; };
    _configText = mkOption { internal = true; };
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
      unitConfig = {
        Unit = {
          Description = "Podman pod ${name}";
        } // config.unitConfig;
        Install = {
          WantedBy = if config.autoStart then [ "default.target" ] else [ ];
        };
        Pod = quadletUtils.configToProperties podConfig podOpts;
        Service = serviceConfigDefault // config.serviceConfig;
      };
    in
    {
      _name = podName;
      _configName = "${name}.pod";
      _unitName = "${name}-pod.service";
      _configText = quadletUtils.unitConfigToText unitConfig;
    };
}
