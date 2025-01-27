{
  stdenvNoCC,
  lib,
  epnixLib,
  fetchFromGitHub,
  jdk,
  ant,
  dos2unix,
  tomcat9,
  python3,
}:
stdenvNoCC.mkDerivation (self: {
  pname = "archiver-appliance";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "archiver-appliance";
    repo = "epicsarchiverap";
    rev = self.version;
    fetchSubmodules = true;
    hash = "sha256-ezsjqp23BMLpqA6cdd6k0wXhAR1imOm0tyWJUaSWmiA=>";
  };

  patches = [
    # Tries to use 'git log'
    ./skip-release-notes.patch

    # Messes up the shebang auto-patching
    ./fix-policies-shebang.patch
  ];

  nativeBuildInputs = [jdk ant dos2unix];
  buildInputs = [python3];

  TOMCAT_HOME = "${tomcat9}";

  buildPhase = ''
    runHook preBuild

    ant

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dt $out/webapps ../retrieval.war ../engine.war ../etl.war ../mgmt.war
    install -Dt $out/share/doc/archappl LICENSE NOTICE
    cp -R docs $out/share/doc/archappl

    install -Dt $out/share/archappl/sql src/main/org/epics/archiverappliance/config/persistence/*.sql
    install -Dt $out/share/archappl/ src/sitespecific/tests/classpathfiles/policies.py
    # DOS-style line-ending messes up shebang auto-patching
    dos2unix $out/share/archappl/policies.py

    install -Dt $out ../archappl*.tar.gz

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
  };
})
