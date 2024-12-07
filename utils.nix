{ lib, systemdUtils, isUserSystemd, podmanPackage }:

let
  attrsToList =
    attrs:
    if builtins.isAttrs attrs then
      lib.mapAttrsToList (name: value: "${name}=${toString value}") attrs
    else
      attrs;
in
{
  mkOption =
    { property, ... }@attrs:
    (lib.mkOption (lib.filterAttrs (name: _: name != "property") attrs))
    // {
      inherit property;
    };

  configToProperties =
    config: options:
    lib.mapAttrs' (name: value: lib.nameValuePair options.${name}.property (attrsToList value)) (
      lib.filterAttrs (_: value: value != null) config
    );

  unitConfigToText =
    unitConfig:
    builtins.concatStringsSep "\n\n" (
      lib.mapAttrsToList (name: section: "[${name}]\n${systemdUtils.lib.attrsToSection section}") unitConfig
    );

  inherit (systemdUtils.unitOptions) unitOption;

  # systemd recommends multi-user.target over default.target.
  # https://www.freedesktop.org/software/systemd/man/latest/systemd.special.html#default.target
  defaultTarget = if isUserSystemd then "default.target" else "multi-user.target";

  inherit podmanPackage;
}
