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
      encoding = "quoted_unescaped";
    };

    addHosts = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "hostname:192.168.10.11" ];
      description = "--add-host";
      property = "AddHost";
    };

    devices = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/dev/foo" ];
      description = "--device";
      property = "AddDevice";
      encoding = "quoted_unescaped";
    };

    annotations = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "XYZ" ];
      description = "--annotation";
      property = "Annotation";
      encoding = "quoted_escaped";
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

    cgroupsMode = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "no-conmon";
      description = "--cgroups";
      property = "CgroupsMode";
    };

    name = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "name";
      description = "--name";
      property = "ContainerName";
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
      encoding = "quoted_unescaped";
    };

    entrypoint = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/foo.sh";
      description = "--entrypoint";
      property = "Entrypoint";
    };

    environments = quadletUtils.mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        foo = "bar";
      };
      description = "--env";
      property = "Environment";
      encoding = "quoted_escaped";
    };

    environmentFiles = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/tmp/env" ];
      description = "--env-file";
      property = "EnvironmentFile";
      encoding = "quoted_escaped";
    };

    environmentHost = quadletUtils.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "--env-host";
      property = "EnvironmentHost";
    };

    exec = quadletUtils.mkOption {
      type = types.nullOr (
        types.oneOf [
          types.str
          (types.listOf types.str)
        ]
      );
      default = null;
      example = "/usr/bin/command";
      description = "Command after image specification";
      property = "Exec";
      # CAVEAT: doesn't prevent systemd environment variable substitution, but probably a quadlet problem?
      encoding = "quoted_escaped_singleline";
    };

    exposePorts = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "50-59" ];
      description = "--expose";
      property = "ExposeHostPort";
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

    group = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "1234";
      description = "--user UID:...";
      property = "Group";
    };

    addGroups = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "keep-groups" ];
      description = "--group-add";
      property = "GroupAdd";
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

    healthLogDestination = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/foo/log";
      description = "--health-log-destination";
      property = "HealthLogDestination";
    };

    healthMaxLogCount = quadletUtils.mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 5;
      description = "--health-max-log-count";
      property = "HealthMaxLogCount";
    };

    healthMaxLogSize = quadletUtils.mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 500;
      description = "	--health-max-log-size";
      property = "HealthMaxLogSize";
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
      type = types.nullOr types.str;
      default = null;
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
      encoding = "quoted_escaped";
    };

    logDriver = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "journald";
      description = "--log-driver";
      property = "LogDriver";
    };

    logOptions = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "path=/var/log/mykube.json" ];
      description = "--log-opt";
      property = "LogOpt";
      encoding = "quoted_unescaped";
    };

    mask = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/proc/sys/foo:/proc/sys/bar";
      description = "--security-opt mask=...";
      property = "Mask";
      encoding = "quoted_escaped";
    };

    mounts = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "type=..." ];
      description = "--mount";
      property = "Mount";
      encoding = "quoted_escaped";
    };

    networks = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "host" ];
      description = "--net";
      property = "Network";
    };

    networkAliases = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "name" ];
      description = "--network-alias";
      property = "NetworkAlias";
    };

    noNewPrivileges = quadletUtils.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "--security-opt no-new-privileges";
      property = "NoNewPrivileges";
    };

    notify = quadletUtils.mkOption {
      type = types.enum [
        null
        true
        false
        "healthy"
      ];
      default = null;
      description = "--sdnotify container";
      property = "Notify";
    };

    pidsLimit = quadletUtils.mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 10000;
      description = "--pids-limit";
      property = "PidsLimit";
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
      encoding = "quoted_escaped";
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

    readOnlyTmpfs = quadletUtils.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "--read-only-tmpfs";
      property = "ReadOnlyTmpfs";
    };

    rootfs = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/var/lib/rootfs";
      description = "--rootfs";
      property = "Rootfs";
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
      encoding = "quoted_escaped";
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

    startWithPod = quadletUtils.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "If pod is defined, container is started by pod";
      property = "StartWithPod";
    };

    stopSignal = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "SIGINT";
      description = "--stop-signal";
      property = "StopSignal";
    };

    stopTimeout = quadletUtils.mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 20;
      description = "--stop-timeout";
      property = "StopTimeout";
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

    sysctl = quadletUtils.mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        name = "value";
      };
      description = "--sysctl";
      property = "Sysctl";
      encoding = "quoted_unescaped";
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

    uidMaps = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "0:10000:10" ];
      description = "--uidmap";
      property = "UIDMap";
      encoding = "quoted_unescaped";
    };

    ulimits = quadletUtils.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "nofile=1000:10000" ];
      description = "--ulimit";
      property = "Ulimit";
    };

    unmask = quadletUtils.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "ALL";
      description = "--security-opt unmask=...";
      property = "Unmask";
      encoding = "quoted_escaped";
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

    quadletConfig = quadletUtils.quadletOpts;

    containerConfig = containerOpts;

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
      containerName = if config.containerConfig.name != null then config.containerConfig.name else name;
      containerConfig = config.containerConfig // {
        name = containerName;
      };
      quadlet = quadletUtils.configToProperties config.quadletConfig quadletUtils.quadletOpts;
      unitConfig = {
        Unit = {
          Description = "Podman container ${name}";
        } // config.unitConfig;
        Container = quadletUtils.configToProperties containerConfig containerOpts;
        Service = serviceConfigDefault // config.serviceConfig;
      } // (if quadlet == { } then { } else { Quadlet = quadlet; });
    in
    {
      _serviceName = name;
      _configText =
        if config.rawConfig != null then config.rawConfig else quadletUtils.unitConfigToText unitConfig;
      _autoStart = config.autoStart;
      _autoEscapeRequired = quadletUtils.autoEscapeRequired containerConfig containerOpts;
      ref = "${name}.container";
    };
}
