{
  stdenv,
  lib,
  makeWrapper,
  perl,
  epnix,
  buildPackages,
  readline,
  ...
}: {
  pname,
  varname,
  epics-base ? epnix.epics-base,
  local_config_site ? {},
  local_release ? {},
  isEpicsBase ? false,
  depsBuildBuild ? [],
  nativeBuildInputs ? [],
  buildInputs ? [],
  shellHook ? "",
  ...
} @ attrs: let
  # remove non standard attributes that cannot be coerced to strings
  overridable = builtins.removeAttrs attrs ["local_config_site" "local_release"];
  generateConf = (buildPackages.epnixLib.formats.make {}).generate;
in
  stdenv.mkDerivation (overridable
    // {
      strictDeps = true;

      # When cross-compiling,
      # epics will build every project twice,
      # once "build -> build", and once "build -> host",
      # so we need a compiler for the "build -> build" compilation.
      depsBuildBuild = depsBuildBuild ++ [buildPackages.stdenv.cc];

      nativeBuildInputs =
        nativeBuildInputs
        ++ [
          makeWrapper
          perl
          readline
          epnix.epicsSetupHook
        ];

      # Also add perl into the non-native build inputs
      # so that shebangs gets patched
      buildInputs =
        buildInputs
        ++ [perl readline]
        ++ (lib.optional (!isEpicsBase) epics-base);

      setupHook = ./setup-hook.sh;

      local_config_site = generateConf local_config_site;
      local_release = generateConf local_release;

      doCheck = attrs.doCheck or true;
      checkTarget = "runtests";

      shellHook = ''
        ${lib.optionalString (!isEpicsBase) ''
          # epics-base is considered a "buildInputs",
          # not a "nativeBuildInputs",
          # so it needs to be manually added in to the PATH
          # in a development shell,
          addToSearchPath PATH "${epics-base}/bin"
        ''}

        ${shellHook}
      '';
    })
