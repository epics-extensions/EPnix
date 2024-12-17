{
  description = "EPICS IOC for migration demonstration purposes";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.epnix.url = "github:epics-extensions/epnix/nixos-24.11";

  inputs.mySupportModule = {
    url = "git+ssh://git@my-server.org/me/exampleApp.git";
    inputs.epnix.follows = "epnix";
  };

  inputs.exampleApp = {
    url = "git+ssh://git@my-server.org/me/exampleApp.git";
    flake = false;
  };

  outputs = {
    self,
    flake-utils,
    epnix,
    ...
  } @ inputs: let
    myEpnixConfig = {pkgs, ...}: {
      nixpkgs.overlays = [inputs.mySupportModule.overlays.default];

      epnix = {
        inherit inputs;

        meta.name = "myExampleTop";

        support.modules = with pkgs.epnix.support; [StreamDevice mySupportModule];
        applications.apps = ["inputs.exampleApp"];

        buildConfig.attrs.buildInputs = [pkgs.openssl];
        buildConfig.attrs.nativeBuildInputs = [pkgs.openssl];

        checks.imports = [./checks/simple.nix];

        nixos.services.myExampleIoc = {
          app = "myExample";
          ioc = "iocMyExample";
        };
      };
    };
  in
    # Add your supported systems here.
    # ---
    # "x86_64-linux" should still be specified so that the development
    # environment can be built on your machine.
    flake-utils.lib.eachSystem ["x86_64-linux"] (system: let
      epnixDistribution = epnix.lib.evalEpnixModules {
        nixpkgsConfig = {
          # This specifies the build architecture
          inherit system;

          # This specifies the host architecture, uncomment for cross-compiling
          #
          # The complete of example architectures is here:
          # https://github.com/NixOS/nixpkgs/blob/nixos-22.11/lib/systems/examples.nix
          # ---
          #crossSystem = epnix.inputs.nixpkgs.lib.systems.examples.armv7l-hf-multiplatform;
        };
        epnixConfig = myEpnixConfig;
      };
    in {
      packages =
        epnixDistribution.outputs
        // {
          default = self.packages.${system}.build;
        };

      inherit epnixDistribution;

      devShells.default = self.packages.${system}.devShell;

      checks = epnixDistribution.config.epnix.checks.derivations;
    })
    // {
      overlays.default = final: prev:
        self.epnixDistribution.x86_64-linux.generatedOverlay final prev;
    };
}
