{ quadletUtils, quadletOptions }:
{
  config,
  name,
  lib,
  ...
}:
let
  inherit (lib) types;

  containerOpts = {
    addCapabilities = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "NET_ADMIN" ];
      description = "--cap-add";
      property = "AddCapability";
      encoding = "quoted_unescaped";
    };

    addHosts = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = ["hostname:192.168.10.11"];
      description = "--add-host";
      property = "AddHost";
    };

    devices = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/dev/foo" ];
      description = "--device";
      property = "AddDevice";
      encoding = "quoted_unescaped";
    };

    annotations = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "XYZ" ];
      description = "--annotation";
      property = "Annotation";
      encoding = "quoted_escaped";
    };

    autoUpdate = quadletOptions.mkOption {
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

    cgroupsMode = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "no-conmon";
      description = "--cgroups";
      property = "CgroupsMode";
    };

    name = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "name";
      description = "--name";
      property = "ContainerName";
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

    dnsSearch = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "foo.com" ];
      description = "--dns-search";
      property = "DNSSearch";
    };

    dnsOption = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "ndots:1" ];
      description = "--dns-option";
      property = "DNSOption";
    };

    dropCapabilities = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "NET_ADMIN" ];
      description = "--cap-drop";
      property = "DropCapability";
      encoding = "quoted_unescaped";
    };

    entrypoint = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/foo.sh";
      description = "--entrypoint";
      property = "Entrypoint";
    };

    environments = quadletOptions.mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        foo = "bar";
      };
      description = "--env";
      property = "Environment";
      encoding = "quoted_escaped";
    };

    environmentFiles = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/tmp/env" ];
      description = "--env-file";
      property = "EnvironmentFile";
      encoding = "quoted_escaped";
    };

    environmentHost = quadletOptions.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "--env-host";
      property = "EnvironmentHost";
    };

    exec = quadletOptions.mkOption {
      type = types.nullOr (types.oneOf [ types.str (types.listOf types.str) ]);
      default = null;
      example = "/usr/bin/command";
      description = "Command after image specification";
      property = "Exec";
      # CAVEAT: doesn't prevent systemd environment variable substitution, but probably a quadlet problem?
      encoding = "quoted_escaped_singleline";
    };

    exposePorts = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "50-59" ];
      description = "--expose";
      property = "ExposeHostPort";
    };

    gidMaps = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [  ];
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

    group = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "1234";
      description = "--user UID:...";
      property = "Group";
    };

    addGroups = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "keep-groups" ];
      description = "--group-add";
      property = "GroupAdd";
    };

    healthCmd = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/usr/bin/command";
      description = "--health-cmd";
      property = "HealthCmd";
    };

    healthInterval = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "2m";
      description = "--health-interval";
      property = "HealthInterval";
    };

    healthLogDestination = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/foo/log";
      description = "--health-log-destination";
      property = "HealthLogDestination";
    };

    healthMaxLogCount = quadletOptions.mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 5;
      description = "--health-max-log-count";
      property = "HealthMaxLogCount";
    };

    healthMaxLogSize = quadletOptions.mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 500;
      description = "	--health-max-log-size";
      property = "HealthMaxLogSize";
    };

    healthOnFailure = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "kill";
      description = "--health-on-failure";
      property = "HealthOnFailure";
    };

    healthRetries = quadletOptions.mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 5;
      description = "--health-retries";
      property = "HealthRetries";
    };

    healthStartPeriod = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "1m";
      description = "--health-start-period";
      property = "HealthStartPeriod";
    };

    healthStartupCmd = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/usr/bin/command";
      description = "--health-startup-cmd";
      property = "HealthStartupCmd";
    };

    healthStartupInterval = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "1m";
      description = "--health-startup-interval";
      property = "HealthStartupInterval";
    };

    healthStartupRetries = quadletOptions.mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 8;
      description = "--health-startup-retries";
      property = "HealthStartupRetries";
    };

    healthStartupSuccess = quadletOptions.mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 2;
      description = "--health-startup-success";
      property = "HealthStartupSuccess";
    };

    healthStartupTimeout = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "1m33s";
      description = "--health-startup-timeout";
      property = "HealthStartupTimeout";
    };

    healthTimeout = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "20s";
      description = "--health-timeout";
      property = "HealthTimeout";
    };

    hostname = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "new-host-name";
      description = "--hostname";
      property = "HostName";
    };

    image = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "docker.io/library/nginx:latest";
      description = "Image specification";
      property = "Image";
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
      example = "fd46:db93:aa76:ac37::10";
      description = "--ip6";
      property = "IP6";
    };

    labels = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "XYZ" ];
      description = "--label";
      property = "Label";
      encoding = "quoted_escaped";
    };

    logDriver = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "journald";
      description = "--log-driver";
      property = "LogDriver";
    };

    logOptions = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "path=/var/log/mykube.json" ];
      description = "--log-opt";
      property = "LogOpt";
      encoding = "quoted_unescaped";
    };

    mask = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/proc/sys/foo:/proc/sys/bar";
      description = "--security-opt mask=...";
      property = "Mask";
      encoding = "quoted_escaped";
    };

    mounts = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "type=..." ];
      description = "--mount";
      property = "Mount";
      encoding = "quoted_escaped";
    };

    networks = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "host" ];
      description = "--net";
      property = "Network";
    };

    networkAliases = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "name" ];
      description = "--network-alias";
      property = "NetworkAlias";
    };

    noNewPrivileges = quadletOptions.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "--security-opt no-new-privileges";
      property = "NoNewPrivileges";
    };

    notify = quadletOptions.mkOption {
      type = types.enum [ null true false "healthy" ];
      default = null;
      description = "--sdnotify container";
      property = "Notify";
    };

    pidsLimit = quadletOptions.mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 10000;
      description = "--pids-limit";
      property = "PidsLimit";
    };

    pod = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "The full name of the pod to link to.";
      property = "Pod";
    };

    podmanArgs = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--add-host foobar" ];
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

    pull = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "never";
      description = "--pull";
      property = "Pull";
    };

    readOnly = quadletOptions.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "--read-only";
      property = "ReadOnly";
    };

    readOnlyTmpfs = quadletOptions.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "--read-only-tmpfs";
      property = "ReadOnlyTmpfs";
    };

    rootfs = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/var/lib/rootfs";
      description = "--rootfs";
      property = "Rootfs";
    };

    runInit = quadletOptions.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "--init";
      property = "RunInit";
    };

    seccompProfile = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/tmp/s.json";
      description = "--security-opt seccomp=...";
      property = "SeccompProfile";
    };

    secrets = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "secret[,opt=opt …]" ];
      description = "--secret";
      property = "Secret";
      encoding = "quoted_escaped";
    };

    securityLabelDisable = quadletOptions.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "--security-opt label=disable";
      property = "SecurityLabelDisable";
    };

    securityLabelFileType = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "usr_t";
      description = "--security-opt label=filetype:...";
      property = "SecurityLabelFileType";
    };

    securityLabelLevel = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "s0:c1,c2";
      description = "--security-opt label=level:s0:c1,c2";
      property = "SecurityLabelLevel";
    };

    securityLabelNested = quadletOptions.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "--security-opt label=nested";
      property = "SecurityLabelNested";
    };

    securityLabelType = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "spc_t";
      description = "--security-opt label=type:...";
      property = "SecurityLabelType";
    };

    shmSize = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "100m";
      description = "--shm-size";
      property = "ShmSize";
    };

    startWithPod = quadletOptions.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = "If pod is defined, container is started by pod";
      property = "StartWithPod";
    };

    stopSignal = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "SIGINT";
      description = "--stop-signal";
      property = "StopSignal";
    };

    stopTimeout = quadletOptions.mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 20;
      description = "--stop-timeout";
      property = "StopTimeout";
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

    sysctl = quadletOptions.mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        name = "value";
      };
      description = "--sysctl";
      property = "Sysctl";
      encoding = "quoted_unescaped";
    };

    timezone = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "local";
      description = "--tz";
      property = "TimeZone";
    };

    tmpfses = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/work" ];
      description = "--tmpfs";
      property = "Tmpfs";
    };

    uidMaps = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "0:10000:10" ];
      description = "--uidmap";
      property = "UIDMap";
      encoding = "quoted_unescaped";
    };

    ulimits = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "nofile=1000:10000" ];
      description = "--ulimit";
      property = "Ulimit";
    };

    unmask = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "ALL";
      description = "--security-opt unmask=...";
      property = "Unmask";
      encoding = "quoted_escaped";
    };

    user = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "bin";
      description = "--user";
      property = "User";
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

    workdir = quadletOptions.mkOption {
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
  options = quadletOptions.mkObjectOptions "container" {
    containerConfig = containerOpts;
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
      _configText = if config.rawConfig != null
        then config.rawConfig
        else quadletUtils.unitConfigToText unitConfig;
      _autoStart = config.autoStart;
      _autoEscapeRequired = quadletUtils.autoEscapeRequired containerConfig containerOpts;
      ref = "${name}.container";
    };
}
