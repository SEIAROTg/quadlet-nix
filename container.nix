{ quadletUtils }:
{
  config,
  name,
  lib,
  ...
}:
let
  inherit (lib) types mkOption;

  containerOpts = {
    addCapabilities = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "NET_ADMIN" ];
      description = "--cap-add";
      property = "AddCapability";
    };

    addHosts = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = ["hostname:192.168.10.11"];
      description = "--add-host";
      property = "AddHost";
    };

    devices = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/dev/foo" ];
      description = "--device";
      property = "AddDevice";
    };

    annotations = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "XYZ" ];
      description = "--annotation";
      property = "Annotation";
    };

    autoUpdate = quadletUtils.mkOption {
      type = types.nullOr (
        types.enum [
          "registry"
          "local"
        ]
      );
      default = null;
      example = "registry";
      description = "--label \"io.containers.autoupdate=...\"";
      property = "AutoUpdate";
    };

    name = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "name";
      description = "--name";
      property = "ContainerName";
    };

    dns = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "192.168.55.1" ];
      description = "--dns";
      property = "DNS";
    };

    dnsSearch = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "foo.com" ];
      description = "--dns-search";
      property = "DNSSearch";
    };

    dnsOption = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "ndots:1" ];
      description = "--dns-option";
      property = "DNSOption";
    };

    dropCapabilities = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "NET_ADMIN" ];
      description = "--cap-drop";
      property = "DropCapability";
    };

    environments = quadletUtils.mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        foo = "bar";
      };
      description = "--env";
      property = "Environment";
    };

    environmentFiles = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/tmp/env" ];
      description = "--env-file";
      property = "EnvironmentFile";
    };

    environmentHost = quadletUtils.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "--env-host";
      property = "EnvironmentHost";
    };

    exec = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/usr/bin/command";
      description = "Command after image specification";
      property = "Exec";
    };

    exposePorts = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "50-59" ];
      description = "--expose";
      property = "ExposeHostPort";
    };

    group = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "1234";
      description = "--user UID:...";
      property = "Group";
    };
    
    gidMap = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "0:10000:10";
      description = "--gidmap";
      property = "GIDMap";
    };

    healthCmd = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/usr/bin/command";
      description = "--health-cmd";
      property = "HealthCmd";
    };

    healthInterval = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "2m";
      description = "--health-interval";
      property = "HealthInterval";
    };

    healthOnFailure = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "kill";
      description = "--health-on-failure";
      property = "HealthOnFailure";
    };

    healthRetries = quadletUtils.mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 5;
      description = "--health-retries";
      property = "HealthRetries";
    };

    healthStartPeriod = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "1m";
      description = "--health-start-period";
      property = "HealthStartPeriod";
    };

    healthStartupCmd = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/usr/bin/command";
      description = "--health-startup-cmd";
      property = "HealthStartupCmd";
    };

    healthStartupInterval = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "1m";
      description = "--health-startup-interval";
      property = "HealthStartupInterval";
    };

    healthStartupRetries = quadletUtils.mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 8;
      description = "--health-startup-retries";
      property = "HealthStartupRetries";
    };

    healthStartupSuccess = quadletUtils.mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 2;
      description = "--health-startup-success";
      property = "HealthStartupSuccess";
    };

    healthStartupTimeout = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "1m33s";
      description = "--health-startup-timeout";
      property = "HealthStartupTimeout";
    };

    healthTimeout = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "20s";
      description = "--health-timeout";
      property = "HealthTimeout";
    };

    hostname = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "new-host-name";
      description = "--hostname";
      property = "HostName";
    };

    image = quadletUtils.mkOption {
      type = types.nonEmptyStr;
      example = "docker.io/library/nginx:latest";
      description = "Image specification";
      property = "Image";
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
      example = "fd46:db93:aa76:ac37::10";
      description = "--ip6";
      property = "IP6";
    };

    labels = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "XYZ" ];
      description = "--label";
      property = "Label";
    };

    logDriver = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "journald";
      description = "--log-driver";
      property = "LogDriver";
    };

    mounts = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "type=..." ];
      description = "--mount";
      property = "Mount";
    };

    networks = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "host" ];
      description = "--net";
      property = "Network";
    };

    noNewPrivileges = quadletUtils.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "--security-opt no-new-privileges";
      property = "NoNewPrivileges";
    };

    rootfs = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/var/lib/rootfs";
      description = "--rootfs";
      property = "Rootfs";
    };

    notify = quadletUtils.mkOption {
      type = types.enum [ null true false "healthy" ];
      default = null;
      description = "--sdnotify container";
      property = "Notify";
    };

    pod = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "The full name of the pod to link to.";
      property = "Pod";
    };

    podmanArgs = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--add-host foobar" ];
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

    pull = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "never";
      description = "--pull";
      property = "Pull";
    };

    readOnly = quadletUtils.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "--read-only";
      property = "ReadOnly";
    };

    runInit = quadletUtils.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "--init";
      property = "RunInit";
    };

    seccompProfile = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/tmp/s.json";
      description = "--security-opt seccomp=...";
      property = "SeccompProfile";
    };

    secrets = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "secret[,opt=opt …]" ];
      description = "--secret";
      property = "Secret";
    };

    securityLabelDisable = quadletUtils.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "--security-opt label=disable";
      property = "SecurityLabelDisable";
    };

    securityLabelFileType = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "usr_t";
      description = "--security-opt label=filetype:...";
      property = "SecurityLabelFileType";
    };

    securityLabelLevel = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "s0:c1,c2";
      description = "--security-opt label=level:s0:c1,c2";
      property = "SecurityLabelLevel";
    };

    securityLabelNested = quadletUtils.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "--security-opt label=nested";
      property = "SecurityLabelNested";
    };

    securityLabelType = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "spc_t";
      description = "--security-opt label=type:...";
      property = "SecurityLabelType";
    };

    shmSize = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "100m";
      description = "--shm-size";
      property = "ShmSize";
    };

    sysctl = quadletUtils.mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        name = "value";
      };
      description = "--sysctl";
      property = "Sysctl";
    };

    timezone = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "local";
      description = "--tz";
      property = "TimeZone";
    };

    tmpfses = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/work" ];
      description = "--tmpfs";
      property = "Tmpfs";
    };

    uidMap = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "0:10000:10";
      description = "--uidmap";
      property = "UIDMap";
    };

    user = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "bin";
      description = "--user";
      property = "User";
    };

    userns = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "keep-id:uid=200,gid=210";
      description = "--userns";
      property = "UserNS";
    };

    volatileTmp = quadletUtils.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "--tmpfs /tmp";
      property = "VolatileTmp";
    };

    volumes = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/source:/dest" ];
      description = "--volume";
      property = "Volume";
    };

    workdir = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "$HOME";
      description = "--workdir";
      property = "WorkingDir";
    };
  };

  serviceConfigDefault = {
    Restart = "always";
    # podman rootless requires "newuidmap" (the suid version, not the non-suid one from pkgs.shadow)
    Environment = "PATH=/run/wrappers/bin";
    TimeoutStartSec = 900;
  };
in
{
  options = {
    autoStart = mkOption {
      type = types.bool;
      default = true;
      example = true;
      description = "When enabled, the container is automatically started on boot.";
    };
    containerConfig = containerOpts;
    unitConfig = mkOption {
      type = types.attrsOf quadletUtils.unitOption;
      default = { };
    };
    serviceConfig = mkOption {
      type = types.attrsOf quadletUtils.unitOption;
      default = serviceConfigDefault;
    };

    _name = mkOption { internal = true; };
    _unitName = mkOption { internal = true; };
    _configText = mkOption { internal = true; };
    ref = mkOption { readOnly = true; };
  };

  config =
    let
      containerName = if config.containerConfig.name != null then config.containerConfig.name else name;
      containerConfig = config.containerConfig // {
        name = containerName;
      };
      unitConfig = {
        Unit = {
          Description = "Podman container ${name}";
        } // config.unitConfig;
        Install = {
          WantedBy = if config.autoStart then [ quadletUtils.defaultTarget ] else [ ];
        };
        Container = quadletUtils.configToProperties containerConfig containerOpts;
        Service = serviceConfigDefault // config.serviceConfig;
      };
    in
    {
      _name = containerName;
      _unitName = "${name}.service";
      _configText = quadletUtils.unitConfigToText unitConfig;
      ref = "${name}.container";
    };
}
