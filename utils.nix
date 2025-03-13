{ lib, systemdUtils, podmanPackage, autoEscape }:

let
  # encodes value based on how podman parses them
  # see: https://github.com/containers/podman/blob/main/pkg/systemd/quadlet/quadlet.go
  encodeValue = encoding: value:
    # Lookup, LookupAll, LookupLast, LookupAllRaw, LookupLastRaw
    if encoding == null then
      systemdUtils.lib.toOption value
    # LookupAllArgs, LookupAllKeyVal
    else if encoding == "quoted_escaped" then
      lib.strings.toJSON value  # same as systemdUtils.lib.serviceToUnit
    # LookupAllStrv
    else if encoding == "quoted_unescaped" then
      "\"${value}\""
    # LookupLastArgs
    else if encoding == "quoted_escaped_singleline" then
      if builtins.isString value then
        value
      else
        builtins.concatStringsSep " " (map (lib.strings.toJSON) value)
    else
      throw "quadlet-nix internal error: unknown encoding ${encoding}";

  encodeValueIfNeeded = encoding: value:
    let
      raw = encodeValue null value;
      encoded = encodeValue encoding value;
    in
      if encoding == null then
        raw
      else if (builtins.match ".*[:space:].*" raw) != null then
        encoded
      else if "\"${raw}\"" == encoded then
        raw
      else
        encoded;

  encodeValuesIfNeeded = encoding: values:
    if builtins.isAttrs values then
      lib.mapAttrsToList (name: value: encodeValueIfNeeded encoding "${name}=${value}") values
    else if builtins.isList values && encoding != "quoted_escaped_singleline" then
      map (encodeValueIfNeeded encoding) values
    else
      encodeValueIfNeeded encoding values;

  configToProperties = autoEscape: config: options:
    let
      nonNullConfig = lib.filterAttrs (_: value: value != null) config;
      encode = if autoEscape then encodeValuesIfNeeded else _: encodeValuesIfNeeded null;
      encodeEntry = name: value:
        lib.nameValuePair options.${name}.property
        (encode options.${name}.encoding value);
    in lib.mapAttrs' encodeEntry nonNullConfig;

in
{
  mkOption =
    { property, encoding ? null, ... }@attrs:
    (lib.mkOption (lib.filterAttrs (name: _: !(builtins.elem name [ "property" "encoding" ])) attrs))
    // {
      inherit property;
      inherit encoding;
    };

  configToProperties = config: options: configToProperties autoEscape config options;
  autoEscapeRequired = config: options: configToProperties autoEscape config options != configToProperties true config options;

  unitConfigToText =
    unitConfig:
    builtins.concatStringsSep "\n\n" (
      lib.mapAttrsToList (name: section: "[${name}]\n${systemdUtils.lib.attrsToSection section}") unitConfig
    );

  assertionsToWarnings = asssertions:
    map (x: x.message) (builtins.filter (x: !x.assertion) asssertions);

  inherit (systemdUtils.unitOptions) unitOption;
  inherit podmanPackage;
}
