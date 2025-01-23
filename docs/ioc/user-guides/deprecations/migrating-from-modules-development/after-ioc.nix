{
  mkEpicsPackage,
  epnix,
  openssl,
  inputs,
}:
mkEpicsPackage {
  pname = "myExampleTop";
  version = "0.0.1";
  varname = "MY_EXAMPLE_TOP";

  src = ./.;

  buildInputs = [openssl];
  nativeBuildInputs = [openssl];

  propagatedBuildInputs = [
    epnix.support.StreamDevice
    epnix.support.mySupportModule
  ];

  preConfigure = ''
    echo "Copying exampleApp"
    cp -rTvf --no-preserve=mode ${inputs.exampleApp} ./exampleApp
  '';

  meta = {
    description = "EPICS IOC for migration demonstration purposes";
    homepage = "<homepage URL>";
  };
}
