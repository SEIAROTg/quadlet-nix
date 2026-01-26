{
  lib,
  systemdUtils,
  podmanPackage,
  autoEscape,
}:

let
  # encodes value based on how podman parses them
  # see: https://github.com/containers/podman/blob/main/pkg/systemd/quadlet/quadlet.go
  encoders =
    let
      # wraps a scalar encoder so it tries not escaping if possible
      makePassive =
        f: x:
        let
          raw = systemdUtils.lib.toOption x;
          encoded = f x;
          canSkip = encoded == raw || (builtins.match ".*[ \t\n\r].*" raw == null && "\"${raw}\"" == encoded);
        in
        if canSkip then raw else encoded;

    in
    {
      scalar.legacy = systemdUtils.lib.toOption;

      # Lookup, LookupAll, LookupLast, LookupAllRaw, LookupLastRaw
      scalar.raw =
        x:
        let
          ret = systemdUtils.lib.toOption x;
        in
        if builtins.match ".*[\r\n].*" ret == null then
          ret
        else
          throw "quadlet-nix internal error: unsafe value for scalar.raw option: ${ret}";

      # LookupAllArgs, LookupAllKeyVal
      # same as systemdUtils.lib.serviceToUnit
      scalar.quotedEscaped = makePassive builtins.toJSON;

      # LookupAllStrv
      scalar.quotedUnescaped = makePassive (
        x:
        let
          escaped = builtins.toJSON x;
          unescaped = "\"${systemdUtils.lib.toOption x}\"";
        in
        if escaped == unescaped then
          unescaped
        else
          throw "quadlet-nix internal error: unsafe value for scalar.quotedUnescaped option: ${escaped}"
      );

      list.default = fScalar: x: map fScalar x;

      # LookupLastArgs
      list.oneLine = fScalar: x: builtins.concatStringsSep " " (map fScalar x);

      list.json = builtins.toJSON;

      attrs.default = fScalar: x: lib.mapAttrsToList (k: v: "${k}=${fScalar v}") x;
    };

  encode =
    encoders: value:
    if builtins.isString value || builtins.isInt value || builtins.isBool value then
      encoders.scalar value
    else if builtins.isList value then
      encoders.list value
    else if builtins.isAttrs value then
      encoders.attrs value
    else
      throw "quadlet-nix internal error: unexpected type for encoder";

  finalizeEncoders =
    autoEscape: optionEncoders:
    let
      effEncoders = if autoEscape then optionEncoders else { scalar = encoders.scalar.legacy; };
      scalar = effEncoders.scalar or encoders.scalar.raw;
      list = effEncoders.list or (encoders.list.default scalar);
      attrs = effEncoders.attrs or (encoders.attrs.default scalar);
    in
    {
      inherit scalar list attrs;
    };

  configToProperties =
    autoEscape: config: options:
    let
      nonNullConfig = lib.filterAttrs (_: value: value != null) config;
      encodeEntry =
        name: value:
        lib.nameValuePair options.${name}.property (
          encode (finalizeEncoders autoEscape options.${name}.encoders) value
        );
    in
    lib.mapAttrs' encodeEntry nonNullConfig;

in
{
  configToProperties = config: options: configToProperties autoEscape config options;
  autoEscapeRequired =
    config: options:
    configToProperties autoEscape config options != configToProperties true config options;

  unitConfigToText =
    unitConfig:
    builtins.concatStringsSep "\n\n" (
      lib.mapAttrsToList (
        name: section: "[${name}]\n${systemdUtils.lib.attrsToSection section}"
      ) unitConfig
    );

  assertionsToWarnings =
    asssertions: map (x: x.message) (builtins.filter (x: !x.assertion) asssertions);

  inherit (systemdUtils.unitOptions) unitOption;
  inherit podmanPackage encoders;
}
