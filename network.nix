{ quadletUtils, quadletOptions }:
{
  config,
  name,
  lib,
  ...
}:
let
  inherit (lib) types getExe;
  inherit (quadletUtils) encoders;

  networkOpts = {
    modules = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/etc/nvd.conf" ];
      cli = "--module";
      property = "ContainersConfModule";
    };

    disableDns = quadletOptions.mkOption {
      type = types.nullOr types.bool;
      default = null;
      cli = "--disable-dns";
      property = "DisableDNS";
    };

    dns = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "192.168.55.1" ];
      cli = "--dns";
      property = "DNS";
    };

    driver = quadletOptions.mkOption {
      type = types.nullOr (
        types.enum [
          "bridge"
          "macvlan"
          "ipvlan"
        ]
      );
      default = null;
      example = "bridge";
      cli = "--driver";
      property = "Driver";
    };

    gateways = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "192.168.55.3" ];
      cli = "--gateway";
      property = "Gateway";
    };

    globalArgs = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [  ];
      example = [ "--log-level=debug" ];
      description = "Additional command line arguments to insert between `podman` and `network create`";
      property = "GlobalArgs";
      encoders.scalar = encoders.scalar.quotedEscaped;
    };

    internal = quadletOptions.mkOption {
      type = types.nullOr types.bool;
      default = null;
      cli = "--internal";
      property = "Internal";
    };

    ipamDriver = quadletOptions.mkOption {
      type = types.nullOr (
        types.enum [
          "host-local"
          "dhcp"
          "none"
        ]
      );
      default = null;
      example = "dhcp";
      cli = "--ipam-driver";
      property = "IPAMDriver";
    };

    ipRanges = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "192.168.55.128/25" ];
      cli = "--ip-range";
      property = "IPRange";
    };

    ipv6 = quadletOptions.mkOption {
      type = types.nullOr types.bool;
      default = null;
      cli = "--ipv6";
      property = "IPv6";
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

    name = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "foo";
      description = "Network name as in `podman network create foo`";
      property = "NetworkName";
    };

    networkDeleteOnStop = quadletOptions.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "When set to true the network is deleted when the service is stopped";
      property = "NetworkDeleteOnStop";
    };

    options = quadletOptions.mkOption {
      # TODO: drop string support and remove warning.
      type = types.oneOf [ types.str (types.listOf types.str) (types.attrsOf types.str) ];
      default = { };
      example = {
        isolate = "true";
      };
      cli = "--opt";
      property = "Options";
      encoders.scalar = encoders.scalar.quotedEscaped;
    };

    podmanArgs = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--dns=192.168.55.1" ];
      description = "Additional command line arguments to insert after `podman network create`";
      property = "PodmanArgs";
      encoders.scalar = encoders.scalar.quotedEscaped;
    };

    subnets = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "192.5.0.0/16" ];
      cli = "--subnet";
      property = "Subnet";
    };
  };
in
{
  options = quadletOptions.mkObjectOptions "network" {
    networkConfig = networkOpts;
  };

  config =
    let
      networkName =
        if config.networkConfig.name != null then config.networkConfig.name else name;
      networkConfig = config.networkConfig // {
        name = networkName;
      };
      quadlet = quadletUtils.configToProperties config.quadletConfig quadletOptions.quadletOpts;
      unitConfig = {
        Unit = {
          Description = "Podman network ${name}";
        } // config.unitConfig;
        Network = quadletUtils.configToProperties networkConfig networkOpts;
        Service = {
          # TODO: switches to NetworkDeleteOnStop once podman in stable nixpkgs supports it
          ExecStop = "${getExe quadletUtils.podmanPackage} network rm ${networkName}";
        } // config.serviceConfig;
      } // (if quadlet == { } then { } else { Quadlet = quadlet; });
    in
    {
      _serviceName = "${name}-network";
      _configText = if config.rawConfig != null
        then config.rawConfig
        else quadletUtils.unitConfigToText unitConfig;
      _autoStart = config.autoStart;
      _autoEscapeRequired = quadletUtils.autoEscapeRequired networkConfig networkOpts;
      ref = "${name}.network";
    };
}
