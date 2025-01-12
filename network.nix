{
  quadletUtils,
}:
{
  config,
  name,
  lib,
  ...
}:
let
  inherit (lib) types mkOption getExe;

  networkOpts = {
    modules = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/etc/nvd.conf" ];
      description = "--module";
      property = "ContainersConfModule";
    };

    disableDns = quadletUtils.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "--disable-dns";
      property = "DisableDNS";
    };

    dns = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "192.168.55.1" ];
      description = "--dns";
      property = "DNS";
    };

    driver = quadletUtils.mkOption {
      type = types.nullOr (
        types.enum [
          "bridge"
          "macvlan"
          "ipvlan"
        ]
      );
      default = null;
      example = "bridge";
      description = "--driver";
      property = "Driver";
    };

    gateways = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "192.168.55.3" ];
      description = "--gateway";
      property = "Gateway";
    };

    globalArgs = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [  ];
      example = [ "--log-level=debug" ];
      description = "global args";
      property = "GlobalArgs";
    };

    internal = quadletUtils.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "--internal";
      property = "Internal";
    };

    ipamDriver = quadletUtils.mkOption {
      type = types.nullOr (
        types.enum [
          "host-local"
          "dhcp"
          "none"
        ]
      );
      default = null;
      example = "dhcp";
      description = "--ipam-driver";
      property = "IPAMDriver";
    };

    ipRanges = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "192.168.55.128/25" ];
      description = "--ip-range";
      property = "IPRange";
    };

    ipv6 = quadletUtils.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "--ipv6";
      property = "IPv6";
    };

    labels = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "XYZ" ];
      description = "--label";
      property = "Label";
    };

    name = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "foo";
      description = "podman network create foo";
      property = "NetworkName";
    };

    options = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "isolate";
      description = "--opt";
      property = "Options";
    };

    podmanArgs = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--dns=192.168.55.1" ];
      description = "extra arguments to podman";
      property = "PodmanArgs";
    };

    subnets = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "192.5.0.0/16" ];
      description = "--subnet";
      property = "Subnet";
    };
  };
in
{
  options = {
    autoStart = mkOption {
      type = types.bool;
      default = true;
      example = true;
      description = "When enabled, the network is automatically started on boot.";
    };
    networkConfig = networkOpts;
    unitConfig = mkOption {
      type = types.attrsOf quadletUtils.unitOption;
      default = { };
    };
    serviceConfig = mkOption {
      type = types.attrsOf quadletUtils.unitOption;
      default = { };
    };

    _name = mkOption { internal = true; };
    _serviceName = mkOption { internal = true; };
    _configText = mkOption { internal = true; };
    _autoStart = mkOption { internal = true; };
    ref = mkOption { readOnly = true; };
  };

  config =
    let
      networkName =
        if config.networkConfig.name != null then config.networkConfig.name else "systemd-${name}";
      networkConfig = config.networkConfig;
      unitConfig = {
        Unit = {
          Description = "Podman network ${name}";
        } // config.unitConfig;
        Network = quadletUtils.configToProperties networkConfig networkOpts;
        Service = {
          ExecStop = "${getExe quadletUtils.podmanPackage} network rm ${networkName}";
        } // config.serviceConfig;
      };
    in
    {
      _name = networkName;
      _serviceName = "${name}-network";
      _configText = quadletUtils.unitConfigToText unitConfig;
      _autoStart = config.autoStart;
      ref = "${name}.network";
    };
}
