{ lib, systemdLib }:

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
      lib.mapAttrsToList (name: section: "[${name}]\n${systemdLib.attrsToSection section}") unitConfig
    );
}
