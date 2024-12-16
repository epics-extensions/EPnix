{
  nixosTest,
  epnix,
  epnixLib,
  myIoc,
  ...
}:
nixosTest {
  name = "simple";

  nodes.machine = {
    imports = [epnixLib.inputs.self.nixosModules.nixos];
    environment.systemPackages = [epnix.epics-base];

    services.iocs.myIoc = {
      package = myIoc;
      workingDirectory = "iocBoot/iocMyIoc";
    };
  };

  testScript = ''
    machine.wait_for_unit("default.target")
    machine.wait_for_unit("ioc.service")

    machine.wait_until_succeeds("caget stringin", timeout=10)
    machine.wait_until_succeeds("caget stringout", timeout=10)
    machine.fail("caget non-existing")

    with subtest("testing stringout"):
      def test_stringout(_) -> bool:
        machine.succeed("caput stringout 'hello'")
        status, _output = machine.execute("caget -t stringout | grep -qxF 'hello'")

        return status == 0

      retry(test_stringout)

      assert "hello" not in machine.succeed("caget -t stringin")
  '';
}
