{
  config,
  lib,
  pkgs,
  epnix,
  ...
}:
with lib; {
  options = {
    epnix.inputs = mkOption {
      description = ''
        The flake inputs of your project.

        This allows resolving things like `"inputs.myExampleApp"` in the
        `epnix.applications.apps` configuration option.
      '';
      type = types.attrs;
    };

    epnix.outputs = mkOption {
      description = ''
        Contains an attribute set of build-products for this distribution.

        Notable examples include:

        `build`
          ~ The actual build of this distribution.
      '';
      default = {};
      type = with types; attrsOf package;
    };

    epnix.pkgs = mkOption {
      description = ''
        Contains the set of packages effectively used by this distribution.

        This means for example that the `epics-base` package will refer to the
        release branch 3 or 7, depending on the
        `epnix.epics-base.releaseBranch` option value, and so on.

        These packages will be available as the `legacyPackages` flake output.

        This option is read-only. To modify a set of packages, please use the
        `nixpkgs.overlays` option.
      '';
      default = pkgs;
      defaultText = literalExpression "<the-effective-used-packages>";
      readOnly = true;
      type = types.attrs;
    };
  };

  config = {
    warnings = [
      # Unconditional warning
      ''
        For IOC ${config.epnix.meta.name}:

        Developing IOCs using modules is deprecated,
        and will be removed in version `nixos-26.05`.

        See the User Guide "Migrating from modules development"
        in the IOC documentation
        to see how to migrate your IOC.
      ''
    ];

    nixpkgs.overlays = [
      epnix.inputs.bash-lib.overlay
      epnix.inputs.sphinxcontrib-nixdomain.overlays.default
      epnix.overlays.default
    ];
  };
}
