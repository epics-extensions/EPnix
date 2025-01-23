Migrating from modules development
==================================

.. deprecated:: 25.05

   Developing IOC using NixOS-like modules

Explanation
-----------

NixOS-like modules were used to define your IOC,
for example using code such as this:

.. code-block:: nix
   :caption: Deprecated IOC definition

   myEpnixConfig = {pkgs, ...}: {
     epnix = {
       inherit inputs;

       meta.name = "my-top";

       support.modules = with pkgs.epnix.support; [StreamDevice];

       checks.imports = [./checks/simple.nix];

       nixos.services.ioc = {
         app = "example";
         ioc = "iocExample";
       };
     };
   };

This style of development is deprecated since EPNix version ``nixos-25.05``
and will be removed in EPNix version ``nixos-26.05``.

This style of development was deprecated
because it lead to complex logic inside of EPNix,
and provided no tangible benefit.
Moreover,
support top IOCs are packaged differently inside of EPNix,
in a style much more similar to what you can find in nixpkgs.

The newer way of developing IOCs is more similar to the Nix code you can find in the wild,
which makes public documentation more applicable to EPNix developments.

Copying the new template
------------------------

From the top directory of your IOC,
move your :file:`flake.nix` file and checks out of the way,
and initialize the new template over your project:

.. code-block:: bash
   :caption: Applying the new template

   mv flake.nix flake.nix.old
   mv checks checks.old
   nix flake init -t epnix

Edit the new template
---------------------

Flake
^^^^^

For every flake input that you added in your :file:`flake.nix.old` file,
add them in your new :file:`flake.nix` file.

For every overlay that's in your :file:`flake.nix.old`'s ``nixpkgs.overlays`` attribute,
add them in your new :file:`flake.nix` file,
in ``pkgs``' ``overlays``.

Change the name of your IOC by replacing every instance of ``myIoc`` in :file:`flake.nix`.

.. warning::

   If your top is used as an EPICS support top,
   your package will be located in a different attribute path.

   For example,
   if your package was under ``pkgs.epnix.support.supportTop`` before,
   after the migration it will be exported under ``pkgs.supportTop``.

IOC package
^^^^^^^^^^^

Edit the :file:`ioc.nix` file to match your IOC:

- Change the ``pname``, ``version``, and ``varname`` variables
- Add your EPICS support modules dependencies into ``propagatedBuildInputs``
- Add your system libraries dependencies into both ``nativeBuildInputs`` and ``buildInputs``

If you had :samp:`buildConfig.attrs.{something} = {value};` defined in :file:`flake.nix.old`,
add :samp:`{something} = {value};` to your :file:`ioc.nix` file.

Checks
^^^^^^

For each :file:`checks.old/{check}.nix` file directory,
take the new :file:`checks/simple.nix` as a base and:

- copy the ``testScript`` from your old check into the new one
- if you made changes to ``nodes`` or ``nodes.machine``,
  add them to the new check

External apps (IEE)
-------------------

If you defined external apps in :file:`flake.nix.old` such as this:

.. code-block:: nix
   :caption: Deprecated usage of external apps

   application.apps = [
     "inputs.exampleApp"
   ];

You will need to copy them manually in :file:`ioc.nix`.


To do this,
make sure you've re-added :samp:`inputs.{example}App` to your new :file:`flake.nix`,
and pass your ``inputs`` as argument to your IOC:

.. code-block:: diff
   :caption: :file:`flake.nix`

    overlays.default = final: _prev: {
   -  myIoc = final.callPackage ./ioc.nix {};
   +  myIoc = final.callPackage ./ioc.nix { inherit inputs; };
    };

.. code-block:: diff
   :caption: :file:`ioc.nix`

    {
      mkEpicsPackage,
      lib,
      epnix,
   +  inputs,
    }:
    mkEpicsPackage {
      pname = "myIoc";

Copy your apps manually,
during the ``preConfigure`` phase.
For example,
if you have two apps ``exampleApp`` and ``otherExampleApp``:

.. code-block:: nix
   :caption: :file:`ioc.nix`
   :emphasize-lines: 6-11

   #local_release = {
   #  PCRE_INCLUDE = "${lib.getDev pcre}/include";
   #  PCRE_LIB = "${lib.getLib pcre}/lib";
   #};

   preConfigure = ''
     echo "Copying exampleApp"
     cp -rTvf --no-preserve=mode ${inputs.exampleApp} ./exampleApp
     echo "Copying otherExampleApp"
     cp -rTvf --no-preserve=mode ${inputs.otherExampleApp} ./otherExampleApp
   '';

   meta = {
     description = "A description of my IOC";
     homepage = "<homepage URL>";
     # ...
   };

NixOS machines
--------------

If you have in a single project both a NixOS configuration and an IOC,
you need to adapt your code to package your IOC outside of NixOS modules.

The simplest way to do that
is by separating your IOC into a new project,
and follow the migration guide from there.

Complete example
----------------

Here is a complete example of a successful migration.

Before
^^^^^^

.. literalinclude:: ./migrating-from-modules-development/before-flake.nix
   :caption: :file:`flake.nix` --- Before
   :language: nix

.. literalinclude:: ./migrating-from-modules-development/before-checks-simple.nix
   :caption: :file:`checks/simple.nix` --- Before
   :language: nix

After
^^^^^

.. literalinclude:: ./migrating-from-modules-development/after-flake.nix
   :caption: :file:`flake.nix` --- After
   :language: nix

.. literalinclude:: ./migrating-from-modules-development/after-ioc.nix
   :caption: :file:`flake.nix` --- After
   :language: nix

.. literalinclude:: ./migrating-from-modules-development/after-checks-simple.nix
   :caption: :file:`checks/simple.nix` --- After
   :language: nix
