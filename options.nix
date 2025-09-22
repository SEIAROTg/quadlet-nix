{ lib, quadletUtils }:
let
  mkOption =
    { property, cli ? null, description ? null, encoders ? null, ... }@attrs: let
      descForDesc = if description == null then "" else description + "\n\n";
      descForCli = if cli == null then "" else "and command line argument `${cli}`";
    in
      (lib.mkOption (lib.filterAttrs (name: _: !(builtins.elem name [ "property" "cli" "encoders" ])) attrs))
      // {
        inherit property;
        inherit encoders;
        description = "${descForDesc}Maps to quadlet option `${property}`${descForCli}.";
      };

  quadletOpts = {
    defaultDependencies = mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      description = "Add Quadlet’s default network dependencies to the unit";
      property = "DefaultDependencies";
    };
  };

  mkCommonObjectOptions = objectType: {
    quadletConfig = quadletOpts;

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "When enabled, this ${objectType} is automatically started on boot.";
    };

    unitConfig = lib.mkOption {
      type = lib.types.attrsOf quadletUtils.unitOption;
      default = { };
      description = "systemd unit config passed through to [Unit] section.";
    };

    serviceConfig = lib.mkOption {
      type = lib.types.attrsOf quadletUtils.unitOption;
      default = { };
      description = "systemd service config passed through to [Service] section.";
    };

    rawConfig = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Raw quadlet config text. Using this will cause all other options
        contributing to quadlet files to be ignored. autoStart is not affected.
      '';
    };

    _serviceName = lib.mkOption {
      internal = true;
      description = "Name of the systemd service unit, without the .service suffix.";
    };

    _configText = lib.mkOption {
      internal = true;
      description = "Generated quadlet config text";
    };

    _autoStart = lib.mkOption {
      internal = true;
      description = "Whether the service is automatically started on boot.";
    };

    _autoEscapeRequired = lib.mkOption {
      internal = true;
      description = ''
        Whether `autoEscape` needs to be switched on for correct encoding.
        This is false if already on.
      '';
    };

    ref = lib.mkOption {
      readOnly = true;
      description = ''
        Reference to this ${objectType} from other quadlets.

        Quadlet resolves this to object (e.g. container) names and sets up appropriate systemd dependencies.

        This is recognized for most quadlet native options, but not by Podman command line.
        Using this inside `podmanArgs` will therefore unlikely to work.
      '';
    };
  };

  commonTopLevelOptions = let
    submoduleArgs = { inherit quadletUtils; quadletOptions = self; };
  in {
    builds = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule (import ./build.nix submoduleArgs));
      default = { };
      description = "Image builds";
    };
    containers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule (import ./container.nix submoduleArgs));
      default = { };
      description = "Containers";
    };
    images = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule (import ./image.nix submoduleArgs));
      default = { };
      description = "Image pulls";
    };
    networks = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule (import ./network.nix submoduleArgs));
      default = { };
      description = "Networks";
    };
    pods = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule (import ./pod.nix submoduleArgs));
      default = { };
      description = "Pods";
    };
    volumes = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule (import ./volume.nix submoduleArgs));
      default = { };
      description = "Volumes";
    };
    enable = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      description = "Enables quadlet-nix";
    };
    autoEscape = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enables appropriate quoting / escaping.

        Not enabled by default to avoid breaking existing configurations. In the future this will be required.
      '';
    };
    autoUpdate = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enables podman auto update.";
      };
      calendar = lib.mkOption {
        type = lib.types.str;
        default = "*-*-* 00:00:00";
        description = "Schedule for podman auto update. See `systemd.time(7)` for details.";
      };
    };
  };

  getAllObjects = config: builtins.concatLists (map lib.attrValues [
    config.builds
    config.containers
    config.images
    config.networks
    config.pods
    config.volumes
  ]);

  self = {
    inherit mkOption quadletOpts;

    mkObjectOptions = objectType: extraOptions: lib.attrsets.unionOfDisjoint (mkCommonObjectOptions objectType) extraOptions;

    mkTopLevelOptions = extraOptions: lib.attrsets.unionOfDisjoint commonTopLevelOptions extraOptions;

    inherit getAllObjects;

    mkAssertions = extraAssertions: config: let
      containerPodConflicts = lib.lists.intersectLists (lib.attrNames config.containers) (lib.attrNames config.pods);
    in [
      {
        assertion = containerPodConflicts == [ ];
        message = ''
          The container/pod names should be unique!
          See: https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html#podname
          The following names are not unique: ${lib.concatStringsSep " " containerPodConflicts}
        '';
      }
      {
        assertion = !(builtins.any (p: p._autoEscapeRequired) (getAllObjects config));
        message = ''
          `virtualisation.quadlet.autoEscape = true` is required because this configuration contains characters that require quoting or escaping.

          If you have manual quoting or escaping in place, please undo those and enable `autoEscape`.
        '';
      }
    ] ++ extraAssertions;

    mkWarnings = extraWarnings: config: (quadletUtils.assertionsToWarnings [
      {
        # TODO: drop string support and remove.
        assertion = !(builtins.any (p: builtins.isString p.networkConfig.options) (builtins.attrValues config.networks));
        message = "String value in `virtualisation.quadlet.networks.*.networkConfig.options` is deprecated. Make it a list or attrset instead.";
      }
    ]) ++ extraWarnings;
  };
  in self
