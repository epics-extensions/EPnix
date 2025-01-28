{
  stdenvNoCC,
  lib,
  epnix,
  epnixLib,
  fetchFromGitHub,
  jdk,
  gradle,
  sphinx,
  tomcat9,
  python3Packages,
  python3,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "archiver-appliance";
  version = "2.0.5";

  src = fetchFromGitHub {
    owner = "archiver-appliance";
    repo = "epicsarchiverap";
    rev = finalAttrs.version;
    fetchSubmodules = true;
    hash = "sha256-X1q87+3QZaNv4bY9UjTEEr0Jrv9AEIezhygI9jgNay0=";
  };

  patches = [
    # Tries to use 'git log'
    ./skip-release-notes.patch

    # Messes up the shebang auto-patching
    ./fix-policies-shebang.patch

    ./fix-docs-build-script.patch
  ];

  nativeBuildInputs = [
    jdk
    gradle
    sphinx
    python3Packages.myst-parser
    python3Packages.sphinx-rtd-theme
  ];
  buildInputs = [python3];

  gradleFlags = [
    "-PprojVersion=${finalAttrs.version}"
    "-Dorg.gradle.java.home=${jdk}"
  ];

  # Update by running `nix build .#archiver-appliance.mitmCache.updateScript && ./result`
  mitmCache = gradle.fetchDeps {
    pkg = epnix.archiver-appliance;
    data = ./deps.json;
  };

  # Some PV tests fail
  #doCheck = true;

  TOMCAT_HOME = "${tomcat9}";

  installPhase = ''
    runHook preInstall

    install -Dt $out/webapps build/libs/{retrieval,engine,etl,mgmt}.war
    install --mode=644 -Dt $out/share/doc/archappl LICENSE NOTICE

    install --mode=644 -Dt $out/share/archappl/sql src/main/org/epics/archiverappliance/config/persistence/*.sql
    install -Dt $out/share/archappl/ src/sitespecific/tests/classpathfiles/policies.py

    runHook postInstall
  '';

  meta = {
    description = "Implementation of an archiver for EPICS control systems that aims to archive millions of PVs";
    homepage = "https://epicsarchiver.readthedocs.io/en/stable/";
    license = with lib.licenses;
    with epnixLib.licenses; [
      epics
      # Embedded components
      asl20
      bsd2
      bsd3
      gpl2Only
      mit
      psfl
    ];
    maintainers = with epnixLib.maintainers; [minijackson];
    inherit (jdk.meta) platforms;
    sourceProvenance = with lib.sourceTypes; [
      fromSource
      # gradle dependencies
      binaryBytecode
    ];
  };
})
