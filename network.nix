{ quadletUtils, pkgs }:
{ config, name, lib, ... }:

with lib;

let
  networkOpts = {
    disableDns = quadletUtils.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "--disable-dns";
      property = "DisableDNS";
    };

    driver = quadletUtils.mkOption {
      type = types.nullOr (types.enum [ "bridge" "macvlan" "ipvlan" ]);
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

    internal = quadletUtils.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "--internal";
      property = "Internal";
    };

    ipamDriver = quadletUtils.mkOption {
      type = types.nullOr (types.enum [ "host-local" "dhcp" "none" ]);
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

    # TODO: enable once podman support is released
    # https://github.com/containers/podman/commit/9d9f4aaafea01b6604c3a54b9a934c21090ef64a
    # name = quadletUtils.mkOption {
    #   type = types.nullOr types.str;
    #   default = null;
    #   example = "foo";
    #   description = "podman network create foo";
    #   property = "NetworkName";
    # };

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
in {
  options = {
    autoStart = mkOption {
      type = types.bool;
      default = true;
      example = true;
      description = "When enabled, the network is automatically started on boot.";
    };
    networkConfig = networkOpts;
    unitConfig = mkOption {
      type = types.attrs;
      default = {};
    };
    serviceConfig = mkOption {
      type = types.attrs;
      default = {};
    };

    _etc = mkOption { internal = true; };
    _services = mkOption { internal = true; };
  };

  config = let
    configRelPath = "containers/systemd/${name}.network";
    networkName = "systemd-${name}";
    networkConfig = config.networkConfig;
    unitConfig = {
      Unit = {
        Description = "Podman network ${name}";
      };
      Network = quadletUtils.configToProperties networkConfig networkOpts;
      Service = {
        ExecStop = "${pkgs.podman}/bin/podman network rm ${networkName}";
      } // config.serviceConfig;
    };
    unitConfigText = quadletUtils.unitConfigToText unitConfig;
  in {
    _etc = {
      ${configRelPath} = {
        text = unitConfigText;
        mode = "0600";
      };
    };
    _services = quadletUtils.mkTriggerService {
      name = "${name}-network";
      autoStart = config.autoStart;
      inherit unitConfigText;
    };
  };
}
