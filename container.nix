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

  containerOpts = {
    addCapabilities = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "NET_ADMIN" ];
      cli = "--cap-add";
      property = "AddCapability";
      encoders.scalar = encoders.scalar.quotedUnescaped;
    };

    addHosts = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = ["hostname:192.168.10.11"];
      cli = "--add-host";
      property = "AddHost";
    };

    devices = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/dev/foo" ];
      cli = "--device";
      property = "AddDevice";
      encoders.scalar = encoders.scalar.quotedUnescaped;
    };

    annotations = quadletOptions.mkOption {
      type = types.oneOf [ (types.listOf types.str) (types.attrsOf types.str) ];
      default = { };
      example = {
        annotation = "value";
      };
      cli = "--annotation";
      property = "Annotation";
      encoders.scalar = encoders.scalar.quotedEscaped;
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
      cli = "--label \"io.containers.autoupdate=...\"";
      property = "AutoUpdate";
    };

    cgroupsMode = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "no-conmon";
      cli = "--cgroups";
      property = "CgroupsMode";
    };

    name = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "name";
      cli = "--name";
      property = "ContainerName";
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

    dnsSearch = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "foo.com" ];
      cli = "--dns-search";
      property = "DNSSearch";
    };

    dnsOption = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "ndots:1" ];
      cli = "--dns-option";
      property = "DNSOption";
    };

    dropCapabilities = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "NET_ADMIN" ];
      cli = "--cap-drop";
      property = "DropCapability";
      encoders.scalar = encoders.scalar.quotedUnescaped;
    };

    entrypoint = quadletOptions.mkOption {
      type = types.nullOr (types.oneOf [ types.str (types.listOf types.str) ]);
      default = null;
      example = "/foo.sh";
      cli = "--entrypoint";
      property = "Entrypoint";
      encoders.raw = encoders.scalar.raw;
      encoders.list = encoders.list.json;
    };

    environments = quadletOptions.mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        foo = "bar";
      };
      cli = "--env";
      property = "Environment";
      encoders.scalar = encoders.scalar.quotedEscaped;
    };

    environmentFiles = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/tmp/env" ];
      cli = "--env-file";
      property = "EnvironmentFile";
      encoders.scalar = encoders.scalar.quotedEscaped;
    };

    environmentHost = quadletOptions.mkOption {
      type = types.nullOr types.bool;
      default = null;
      cli = "--env-host";
      property = "EnvironmentHost";
    };

    exec = quadletOptions.mkOption {
      type = types.nullOr (types.oneOf [ types.str (types.listOf types.str) ]);
      default = null;
      example = "/usr/bin/command";
      description = "Command after image specification";
      property = "Exec";
      # CAVEAT: doesn't prevent systemd environment variable substitution, but probably a quadlet problem?
      encoders.scalar = encoders.scalar.raw;
      encoders.list = encoders.list.oneLine encoders.scalar.quotedEscaped;
    };

    exposePorts = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "50-59" ];
      cli = "--expose";
      property = "ExposeHostPort";
    };

    gidMaps = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [  ];
      example = [ "0:10000:10" ];
      cli = "--gidmap";
      property = "GIDMap";
      encoders.scalar = encoders.scalar.quotedUnescaped;
    };

    globalArgs = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [  ];
      example = [ "--log-level=debug" ];
      description = "Additional command line arguments to insert between `podman` and `run`";
      property = "GlobalArgs";
      encoders.scalar = encoders.scalar.quotedEscaped;
    };

    group = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "1234";
      cli = "--user UID:...";
      property = "Group";
    };

    addGroups = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "keep-groups" ];
      cli = "--group-add";
      property = "GroupAdd";
    };

    healthCmd = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/usr/bin/command";
      cli = "--health-cmd";
      property = "HealthCmd";
    };

    healthInterval = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "2m";
      cli = "--health-interval";
      property = "HealthInterval";
    };

    healthLogDestination = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/foo/log";
      cli = "--health-log-destination";
      property = "HealthLogDestination";
    };

    healthMaxLogCount = quadletOptions.mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 5;
      cli = "--health-max-log-count";
      property = "HealthMaxLogCount";
    };

    healthMaxLogSize = quadletOptions.mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 500;
      cli = "--health-max-log-size";
      property = "HealthMaxLogSize";
    };

    healthOnFailure = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "kill";
      cli = "--health-on-failure";
      property = "HealthOnFailure";
    };

    healthRetries = quadletOptions.mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 5;
      cli = "--health-retries";
      property = "HealthRetries";
    };

    healthStartPeriod = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "1m";
      cli = "--health-start-period";
      property = "HealthStartPeriod";
    };

    healthStartupCmd = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/usr/bin/command";
      cli = "--health-startup-cmd";
      property = "HealthStartupCmd";
    };

    healthStartupInterval = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "1m";
      cli = "--health-startup-interval";
      property = "HealthStartupInterval";
    };

    healthStartupRetries = quadletOptions.mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 8;
      cli = "--health-startup-retries";
      property = "HealthStartupRetries";
    };

    healthStartupSuccess = quadletOptions.mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 2;
      cli = "--health-startup-success";
      property = "HealthStartupSuccess";
    };

    healthStartupTimeout = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "1m33s";
      cli = "--health-startup-timeout";
      property = "HealthStartupTimeout";
    };

    healthTimeout = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "20s";
      cli = "--health-timeout";
      property = "HealthTimeout";
    };

    hostname = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "new-host-name";
      cli = "--hostname";
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
      cli = "--ip";
      property = "IP";
    };

    ip6 = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "fd46:db93:aa76:ac37::10";
      cli = "--ip6";
      property = "IP6";
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

    logDriver = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "journald";
      cli = "--log-driver";
      property = "LogDriver";
    };

    logOptions = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "path=/var/log/mykube.json" ];
      cli = "--log-opt";
      property = "LogOpt";
      encoders.scalar = encoders.scalar.quotedUnescaped;
    };

    mask = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/proc/sys/foo:/proc/sys/bar";
      cli = "--security-opt mask=...";
      property = "Mask";
      encoders.scalar = encoders.scalar.quotedEscaped;
    };

    memory = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "20g";
      cli = "--memory";
      property = "Memory";
    };

    mounts = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "type=..." ];
      cli = "--mount";
      property = "Mount";
      encoders.scalar = encoders.scalar.quotedEscaped;
    };

    networks = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "host" ];
      cli = "--net";
      property = "Network";
    };

    networkAliases = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "name" ];
      cli = "--network-alias";
      property = "NetworkAlias";
    };

    noNewPrivileges = quadletOptions.mkOption {
      type = types.nullOr types.bool;
      default = null;
      cli = "--security-opt no-new-privileges";
      property = "NoNewPrivileges";
    };

    notify = quadletOptions.mkOption {
      type = types.enum [ null true false "healthy" ];
      default = null;
      cli = "--sdnotify container";
      property = "Notify";
    };

    pidsLimit = quadletOptions.mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 10000;
      cli = "--pids-limit";
      property = "PidsLimit";
    };

    pod = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      cli = "--pod";
      property = "Pod";
    };

    podmanArgs = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--add-host foobar" ];
      description = "Additional command line arguments to insert after `podman run`";
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

    pull = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "never";
      cli = "--pull";
      property = "Pull";
    };

    readOnly = quadletOptions.mkOption {
      type = types.nullOr types.bool;
      default = null;
      cli = "--read-only";
      property = "ReadOnly";
    };

    readOnlyTmpfs = quadletOptions.mkOption {
      type = types.nullOr types.bool;
      default = null;
      cli = "--read-only-tmpfs";
      property = "ReadOnlyTmpfs";
    };

    reloadCmd = quadletOptions.mkOption {
      type = types.nullOr (types.oneOf [ types.str (types.listOf types.str) ]);
      default = null;
      description = "Adds ExecReload and run exec with the value";
      example = "/usr/bin/command";
      property = "ReloadCmd";
      encoders.scalar = encoders.scalar.raw;
      encoders.list = encoders.list.oneLine encoders.scalar.quotedEscaped;
    };

    reloadSignal = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Add ExecReload and run kill with the signal";
      example = "SIGHUP";
      property = "ReloadSignal";
    };

    retry = quadletOptions.mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 5;
      cli = "--retry";
      property = "Retry";
    };

    retryDelay = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "5s";
      cli = "--retry-delay";
      property = "RetryDelay";
    };

    rootfs = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/var/lib/rootfs";
      cli = "--rootfs";
      property = "Rootfs";
    };

    runInit = quadletOptions.mkOption {
      type = types.nullOr types.bool;
      default = null;
      cli = "--init";
      property = "RunInit";
    };

    seccompProfile = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "/tmp/s.json";
      cli = "--security-opt seccomp=...";
      property = "SeccompProfile";
    };

    secrets = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "secret[,opt=opt …]" ];
      cli = "--secret";
      property = "Secret";
      encoders.scalar = encoders.scalar.quotedEscaped;
    };

    securityLabelDisable = quadletOptions.mkOption {
      type = types.nullOr types.bool;
      default = null;
      cli = "--security-opt label=disable";
      property = "SecurityLabelDisable";
    };

    securityLabelFileType = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "usr_t";
      cli = "--security-opt label=filetype:...";
      property = "SecurityLabelFileType";
    };

    securityLabelLevel = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "s0:c1,c2";
      cli = "--security-opt label=level:s0:c1,c2";
      property = "SecurityLabelLevel";
    };

    securityLabelNested = quadletOptions.mkOption {
      type = types.nullOr types.bool;
      default = null;
      cli = "--security-opt label=nested";
      property = "SecurityLabelNested";
    };

    securityLabelType = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "spc_t";
      cli = "--security-opt label=type:...";
      property = "SecurityLabelType";
    };

    shmSize = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "100m";
      cli = "--shm-size";
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
      cli = "--stop-signal";
      property = "StopSignal";
    };

    stopTimeout = quadletOptions.mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 20;
      cli = "--stop-timeout";
      property = "StopTimeout";
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

    sysctl = quadletOptions.mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        name = "value";
      };
      cli = "--sysctl";
      property = "Sysctl";
      encoders.scalar = encoders.scalar.quotedUnescaped;
    };

    timezone = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "local";
      cli = "--tz";
      property = "Timezone";
    };

    tmpfses = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/work" ];
      cli = "--tmpfs";
      property = "Tmpfs";
    };

    uidMaps = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "0:10000:10" ];
      cli = "--uidmap";
      property = "UIDMap";
      encoders.scalar = encoders.scalar.quotedUnescaped;
    };

    ulimits = quadletOptions.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "nofile=1000:10000" ];
      cli = "--ulimit";
      property = "Ulimit";
    };

    unmask = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "ALL";
      cli = "--security-opt unmask=...";
      property = "Unmask";
      encoders.scalar = encoders.scalar.quotedEscaped;
    };

    user = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "bin";
      cli = "--user";
      property = "User";
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

    workdir = quadletOptions.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "$HOME";
      cli = "--workdir";
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
      quadlet = quadletUtils.configToProperties config.quadletConfig quadletOptions.quadletOpts;
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
