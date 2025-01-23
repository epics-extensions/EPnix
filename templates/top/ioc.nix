{
  mkEpicsPackage,
  lib,
  epnix,
}:
mkEpicsPackage {
  pname = "myIoc";
  version = "0.0.1";
  varname = "MY_IOC";

  src = ./.;

  # For EPICS, native libraries needs to be both in
  # nativeBuildInputs and buildInputs
  # --
  nativeBuildInputs = [];
  buildInputs = [];

  # EPICS support modules can be only in propagatedBuildInputs
  # --
  propagatedBuildInputs = [
    #epnix.support.StreamDevice
  ];

  # Extra variables to put in the RELEASE.local,
  # for example:
  # --
  #local_release = {
  #  PCRE_INCLUDE = "${lib.getDev pcre}/include";
  #  PCRE_LIB = "${lib.getLib pcre}/lib";
  #};

  meta = {
    description = "A description of my IOC";
    homepage = "<homepage URL>";

    # If your IOC is public, add a license.

    # for example:
    # --
    #license = lib.licenses.asl20;

    # another example:
    # --
    #license = epnixLib.licenses.epics;
  };
}
