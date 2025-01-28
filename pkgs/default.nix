epnixLib: inputs: final: prev: let
  inherit (final) callPackage;
  # From prev, else it somehow causes an infinite recursion
  inherit (prev) recurseIntoAttrs;
  recurseExtensible = f: recurseIntoAttrs (final.lib.makeExtensible f);
in
  recurseIntoAttrs {
    inherit epnixLib;

    mkEpicsPackage = callPackage ./build-support/mk-epics-package {};

    pythonPackagesExtensions =
      prev.pythonPackagesExtensions
      ++ [
        (final: prev: {
          lewis = final.callPackage ./epnix/tools/lewis {};
          channelfinder = final.callPackage ./epnix/tools/channel-finder/pyCFClient {};
          pyepics = final.callPackage ./epnix/python-modules/pyepics {};
          recceiver = final.callPackage ./epnix/tools/channel-finder/recceiver {};
          scanf = final.callPackage ./epnix/tools/scanf {};
          epicscorelibs = final.callPackage ./epnix/python-modules/epicscorelibs {};
          pvxslibs = final.callPackage ./epnix/python-modules/pvxslibs {};
          aioca = final.callPackage ./epnix/python-modules/aioca/default.nix {};
          epicsdbbuilder = final.callPackage ./epnix/python-modules/epicsdbbuilder {};
          softioc = final.callPackage ./epnix/python-modules/softioc {};
        })
      ];

    linuxKernel =
      prev.linuxKernel
      // {
        packagesFor = kernel:
          (prev.linuxKernel.packagesFor kernel).extend (final: _prev: {
            mrf = final.callPackage ./epnix/kernel-modules/mrf {};
          });
      };

    epnix = recurseExtensible (self: {
      # EPICS base

      epics-base7 = callPackage ./epnix/epics-base {
        version = "7.0.8.1";
        hash = "sha256-JDSMBwBLZj9aaxJHGg0QmZ1zYTSY8J7+ZGihAwEuz3w=";
      };
      epics-base3 = callPackage ./epnix/epics-base {
        version = "3.15.9";
        hash = "sha256-QWScmCEaG0F6OW6LPCaFur4W57oRl822p7wpzbYhOuA=";
      };
      epics-base = self.epics-base7;

      epicsSetupHook = callPackage ./build-support/epics-setup-hook {};

      # EPICS support modules

      support = recurseExtensible (_self: {
        adsDriver = callPackage ./epnix/support/adsDriver {};
        asyn = callPackage ./epnix/support/asyn {};
        autoparamDriver = callPackage ./epnix/support/autoparamDriver {};
        autosave = callPackage ./epnix/support/autosave {};
        busy = callPackage ./epnix/support/busy {};
        calc = callPackage ./epnix/support/calc {};
        devlib2 = callPackage ./epnix/support/devlib2 {};
        epics-systemd = callPackage ./epnix/support/epics-systemd {};
        gtest = callPackage ./epnix/support/gtest {};
        ipac = callPackage ./epnix/support/ipac {};
        modbus = callPackage ./epnix/support/modbus {};
        mrfioc2 = callPackage ./epnix/support/mrfioc2 {};
        opcua = callPackage ./epnix/support/opcua {open62541 = self.open62541_1_3;};
        pvxs = callPackage ./epnix/support/pvxs {};
        reccaster = callPackage ./epnix/support/reccaster {};
        seq = callPackage ./epnix/support/seq {};
        snmp = callPackage ./epnix/support/snmp {};
        sscan = callPackage ./epnix/support/sscan {};
        StreamDevice = callPackage ./epnix/support/StreamDevice {};
        twincat-ads = callPackage ./epnix/support/twincat-ads {};
      });

      # EPICS related tools and extensions

      archiver-appliance = callPackage ./epnix/tools/archiver-appliance {
        jdk = prev.jdk17;
      };

      ca-gateway = callPackage ./epnix/tools/ca-gateway {};

      channel-finder-service = callPackage ./epnix/tools/channel-finder/service {};

      # Lewis needs Python < 3.12
      inherit (final.python311Packages) lewis;

      inherit (final.python3Packages) pyepics;

      pythonSoftIOC = final.python3Packages.softioc;

      inherit (callPackage ./epnix/tools/lewis/lib.nix {}) mkLewisSimulator;

      pcas = callPackage ./epnix/tools/pcas {};

      phoebus = callPackage ./epnix/tools/phoebus/client {};
      phoebus-unwrapped = callPackage ./epnix/tools/phoebus/client-unwrapped {
        jdk = prev.jdk21;
        openjfx = prev.openjfx21;
      };
      phoebus-alarm-server = callPackage ./epnix/tools/phoebus/alarm-server {};
      phoebus-alarm-logger = callPackage ./epnix/tools/phoebus/alarm-logger {};
      phoebus-archive-engine = callPackage ./epnix/tools/phoebus/archive-engine {};
      phoebus-deps = callPackage ./epnix/tools/phoebus/deps {jdk = prev.jdk21;};
      phoebus-olog = callPackage ./epnix/tools/phoebus/olog {jdk = prev.jdk21;};
      phoebus-pva = callPackage ./epnix/tools/phoebus/pva {};
      phoebus-save-and-restore = callPackage ./epnix/tools/phoebus/save-and-restore {};
      phoebus-scan-server = callPackage ./epnix/tools/phoebus/scan-server {};
      phoebus-setup-hook = callPackage ./epnix/tools/phoebus/setup-hook {jdk = prev.jdk21_headless;};

      procServ = callPackage ./epnix/tools/procServ {};

      # Other utilities

      mariadb_jdbc = callPackage ./epnix/tools/mariadb_jdbc {};
      # Needed by support/opcua
      open62541_1_3 = callPackage ./epnix/tools/open62541_1_3 {};

      # EPNix specific packages
      docs = callPackage ./docs {
        nixdomainLib = inputs.sphinxcontrib-nixdomain.lib;
      };

      # Documentation support packages
      psu-simulator = callPackage ./doc-support/psu-simulator {};

      ci-scripts = recurseExtensible (_self: {
        build-docs-multiversion = callPackage ./ci-scripts/build-docs-multiversion.nix {};
      });
    });
  }
