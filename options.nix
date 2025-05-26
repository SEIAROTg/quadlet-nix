{ lib, quadletUtils }:
let
  mkOption =
    { property, encoding ? null, ... }@attrs:
    (lib.mkOption (lib.filterAttrs (name: _: !(builtins.elem name [ "property" "encoding" ])) attrs))
    // {
      inherit property;
      inherit encoding;
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
    };

    serviceConfig = lib.mkOption {
      type = lib.types.attrsOf quadletUtils.unitOption;
      default = { };
    };

    rawConfig = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };

    _serviceName = lib.mkOption { internal = true; };
    _configText = lib.mkOption { internal = true; };
    _autoStart = lib.mkOption { internal = true; };
    _autoEscapeRequired = lib.mkOption { internal = true; };
    ref = lib.mkOption { readOnly = true; };
  };

  commonTopLevelOptions = let
    submoduleArgs = { inherit quadletUtils; quadletOptions = self; };
  in {
    builds = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule (import ./build.nix submoduleArgs));
      default = { };
    };
    containers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule (import ./container.nix submoduleArgs));
      default = { };
    };
    networks = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule (import ./network.nix submoduleArgs));
      default = { };
    };
    pods = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule (import ./pod.nix submoduleArgs));
      default = { };
    };
    volumes = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule (import ./volume.nix submoduleArgs));
      default = { };
    };
    autoEscape = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enables appropriate quoting / escaping.

        Not enabled by default to avoid breaking existing configurations. In the future this will be required.
      '';
    };
  };

  getAllObjects = config: builtins.concatLists (map lib.attrValues [
    config.builds
    config.containers
    config.networks
    config.pods
    config.volumes
  ]);

  self = {
    inherit mkOption;

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
    ] ++ extraAssertions;

    mkWarnings = extraWarnings: config:
      (quadletUtils.assertionsToWarnings [
        {
          assertion = !(builtins.any (p: p._autoEscapeRequired) (getAllObjects config));
          message = ''
            `virtualisation.quadlet.autoEscape = true` is required because this configuration contains characters that require quoting or escaping.

            This will become a hard error in the future. If you have manual quoting or escaping in place, please undo those and enable `autoEscape`.
          '';
        }
      ]) ++ extraWarnings;
  };
  in self
