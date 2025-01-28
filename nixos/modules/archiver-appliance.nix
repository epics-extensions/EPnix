{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.archiver-appliance;

  hostname = "localhost";

  defaultAppliancesXml = ''
    <appliances>
      <appliance>
        <identity>appliance0</identity>
        <cluster_inetport>${hostname}:16670</cluster_inetport>
        <mgmt_url>http://${hostname}:8080/mgmt/bpl</mgmt_url>
        <engine_url>http://${hostname}:8080/engine/bpl</engine_url>
        <etl_url>http://${hostname}:8080/etl/bpl</etl_url>
        <retrieval_url>http://${hostname}:8080/retrieval/bpl</retrieval_url>
        <data_retrieval_url>http://${hostname}:8080/retrieval</data_retrieval_url>
      </appliance>
    </appliances>
  '';

  contextXml = pkgs.writeTextDir "/context.xml" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!--
      Licensed to the Apache Software Foundation (ASF) under one or more
      contributor license agreements.  See the NOTICE file distributed with
      this work for additional information regarding copyright ownership.
      The ASF licenses this file to You under the Apache License, Version 2.0
      (the "License"); you may not use this file except in compliance with
      the License.  You may obtain a copy of the License at

          http://www.apache.org/licenses/LICENSE-2.0

      Unless required by applicable law or agreed to in writing, software
      distributed under the License is distributed on an "AS IS" BASIS,
      WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
      See the License for the specific language governing permissions and
      limitations under the License.
    -->
    <!-- The contents of this file will be loaded for each web application -->
    <Context>

        <!-- Default set of monitored resources. If one of these changes, the    -->
        <!-- web application will be reloaded.                                   -->
        <WatchedResource>WEB-INF/web.xml</WatchedResource>
        <WatchedResource>WEB-INF/tomcat-web.xml</WatchedResource>
        <WatchedResource>''${catalina.base}/conf/web.xml</WatchedResource>

        <!-- Uncomment this to disable session persistence across Tomcat restarts -->
        <!--
        <Manager pathname="" />
        -->

        <Resource
          name="jdbc/archappl"
          type="javax.sql.DataSource"
          removeAbandonedTimeout="60"
          removeAbandoned="true"
          logAbandoned="true"
          jmxEnabled="true"
          driverClassName="org.mariadb.jdbc.Driver"
          url="jdbc:mariadb://localhost:3306/archappl?localSocket=/run/mysqld/mysqld.sock"
          />
    </Context>
  '';

  loggingProperties = pkgs.writeTextDir "/logging.properties" ''
    .handlers = java.util.logging.ConsoleHandler
  '';

  log4j2Xml = pkgs.writeTextDir "/log4j2.xml" ''
    <Configuration>
      <Appenders>
        <Console name="STDOUT" target="SYSTEM_OUT">
          <PatternLayout pattern="%p %m (%c)%n"/>
        </Console>
        </Appenders>
        <Loggers>
          <Logger name="org.apache.log4j.xml" level="info"/>
          <Root level="info">
            <AppenderRef ref="STDOUT"/>
          </Root>
        </Loggers>
    </Configuration>
  '';
in {
  options.services.archiver-appliance = {
    enable = lib.mkEnableOption ''
      Archiver Appliance.

      Archiver Appliance listens on port 8080'';

    package = lib.mkOption {
      description = "Archiver Appliance package to use.";
      type = lib.types.package;
      default = pkgs.epnix.archiver-appliance;
      defaultText = lib.literalExpression "pkgs.epnix.archiver-appliance";
    };

    # TODO: make port configurable, which is harder than it sounds
    openFirewall = lib.mkOption {
      description = ''
        Open the firewall for the Archiver Appliance service.

        .. warning::
           This opens the firewall on all network interfaces.
      '';
      type = lib.types.bool;
      default = false;
    };

    appliancesXml = lib.mkOption {
      description = ''
        Content of the :file:`appliances.xml` file.

        See the `appliances.xml documentation`_ for more details.

        .. _appliances.xml documentation: https://epicsarchiver.readthedocs.io/en/latest/sysadmin/installguide.html#appliances-xml
      '';
      type = lib.types.str;
      default = defaultAppliancesXml;
    };

    settings = lib.mkOption {
      description = ''
        Configuration for Archiver Appliance.

        These options will be put into the Archiver Appliance's environment.
      '';
      default = {};
      type = lib.types.submodule {
        freeformType = with lib.types; attrsOf (oneOf [str path]);
        options = {
          ARCHAPPL_MYIDENTITY = lib.mkOption {
            description = ''
              The identity of the current appliance.

              If you change this value,
              you will need to modify the content of :file:`appliances.xml`:
              the specified identity must match an identity of one of the appliance XML elements.

              .. seealso::
                :nix:option:`services.archiver-appliance.appliancesXml`
            '';
            type = lib.types.str;
            default = "appliance0";
          };

          ARCHAPPL_APPLIANCES = lib.mkOption {
            description = ''
              Path to an :file:`appliances.xml` file.

              By default this NixOS module will generate a file
              from the :nix:option:`services.archiver-appliance.appliancesXml` option,
              so you might want to modify that instead.
            '';
            type = lib.types.path;
            default = pkgs.writeText "appliances.xml" cfg.appliancesXml;
            defaultText = lib.literalExpression ''pkgs.writeText "appliances.xml" cfg.appliancesXml'';
          };

          ARCHAPPL_POLICIES = lib.mkOption {
            description = ''
              Path to a :file:`policies.py` file.

              This file specifies the various policies
              that can be used when archiving a PV.
              For example,
              you can specify that a given policy archives PVs at a rate of 2Hz.

              By default,
              the :file:`policies.py` found in :file:`src/sitespecific/tests/classpathfiles/policies.py` is used.
            '';
            type = lib.types.path;
            default = "${cfg.package}/share/archappl/policies.py";
            defaultText = lib.literalExpression ''"''${cfg.package}/share/archappl/policies.py"'';
          };

          ARCHAPPL_SHORT_TERM_FOLDER = lib.mkOption {
            description = ''
              Path to the Short Term Store (STS) folder.
            '';
            type = lib.types.path;
            default = "/arch/sts/ArchiverStore";
          };

          ARCHAPPL_MEDIUM_TERM_FOLDER = lib.mkOption {
            description = ''
              Path to the Medium Term Store (MTS) folder.
            '';
            type = lib.types.path;
            default = "/arch/mts/ArchiverStore";
          };

          ARCHAPPL_LONG_TERM_FOLDER = lib.mkOption {
            description = ''
              Path to the Long Term Store (MTS) folder.
            '';
            type = lib.types.path;
            default = "/arch/lts/ArchiverStore";
          };

          EPICS_CA_AUTO_ADDR_LIST = lib.mkOption {
            description = ''
              If set,
              behave as if every broadcast address of every network interface is added to ``EPICS_CA_ADDR_LIST``.
            '';
            type = lib.types.bool;
            default = true;
            apply = b:
              if b
              then "YES"
              else "NO";
          };

          EPICS_CA_ADDR_LIST = lib.mkOption {
            description = ''
              List of Channel Access destination IP addresses.

              Each IP address can be a unicast address,
              or a broadcast address.

              This option is ignored of ``EPICS_CA_AUTO_ADDR_LIST`` is enabled (the default).
            '';
            type = with lib.types; listOf str;
            default = [];
            # Separated by spaces
            apply = toString;
          };
        };
      };
    };

    stores = {
      configure = lib.mkOption {
        description = ''
          Whether to automatically configure the local STS, MTS, and LTS directories.
        '';
        type = lib.types.bool;
        default = true;
      };

      sts.size = lib.mkOption {
        description = ''
          Size of the STS in bytes.

          If null,
          the size will depend on the amount of RAM available,
          normally half of your physical RAM without swap.

          .. warning::
            If you oversize it,
            the machine will deadlock since the OOM handler will not be able to free that memory.
        '';
        example = "20g";
        type = with lib.types; nullOr str;
        default = null;
      };

      mts.location = lib.mkOption {
        description = ''
          Backing directory containing the MTS.
        '';
        example = "/data/mts";
        type = lib.types.str;
      };

      lts.location = lib.mkOption {
        description = ''
          Backing directory containing the LTS.
        '';
        example = "/data/lts";
        type = lib.types.str;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.archiver-appliance.settings.CATALINA_OUT_CMD = "cat";

    services.tomcat = {
      enable = true;

      webapps = [cfg.package];

      extraConfigFiles = [
        "${loggingProperties}/logging.properties"
        "${contextXml}/context.xml"
      ];

      commonLibs = [
        "${log4j2Xml}/log4j2.xml"

        # We use the mariadb connecter, since it supports UNIX socket connection,
        # which allows us not not store the password in plaintext in the config.
        "${pkgs.epnix.mariadb_jdbc}/share/java/mariadb-java-client.jar"

        # Dependencies of the mariadb connector, for UNIX sockets:
        "${pkgs.jna}/share/java/jna.jar"
        "${pkgs.jna}/share/java/jna-platform.jar"
      ];

      user = "archappl";
      group = "archappl";
    };

    systemd.services.tomcat = {
      after = ["mysql.service"];
      wants = ["mysql.service"];

      environment = cfg.settings;
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [8080];

    users.groups."archappl" = {};
    users.users."archappl" = {
      group = "archappl";
      isSystemUser = true;
    };

    services.mysql = {
      enable = true;
      package = pkgs.mariadb;

      initialDatabases = [
        {
          name = "archappl";
          schema = "${cfg.package}/share/archappl/sql/archappl_mysql.sql";
        }
      ];
      ensureUsers = [
        {
          name = "archappl";
          ensurePermissions."archappl.*" = "ALL PRIVILEGES";
        }
      ];
    };

    systemd.mounts = let
      defaultOptions = [
        "rw"
        # Security: only normal files allowed
        "nosuid"
        "noexec"
        "nodev"
      ];
    in
      lib.mkIf cfg.stores.configure [
        # STS
        {
          what = "tmpfs";
          where = "${cfg.settings.ARCHAPPL_SHORT_TERM_FOLDER}";
          type = "tmpfs";
          mountConfig.Options =
            lib.concatStringsSep ","
            (defaultOptions
              ++ lib.optional (cfg.stores.sts.size != null) "size=${cfg.stores.sts.size}");
          wantedBy = ["local-fs.target"];
        }

        # MTS
        {
          what = "${cfg.stores.mts.location}";
          where = "${cfg.settings.ARCHAPPL_MEDIUM_TERM_FOLDER}";
          mountConfig.Options = lib.concatStringsSep "," (defaultOptions ++ ["bind"]);
          wantedBy = ["local-fs.target"];
        }

        # LTS
        {
          what = "${cfg.stores.lts.location}";
          where = "${cfg.settings.ARCHAPPL_LONG_TERM_FOLDER}";
          mountConfig.Options = lib.concatStringsSep "," (defaultOptions ++ ["bind"]);
          wantedBy = ["local-fs.target"];
        }
      ];

    systemd.tmpfiles.rules = lib.mkIf cfg.stores.configure [
      ''Z "${cfg.settings.ARCHAPPL_SHORT_TERM_FOLDER}"  0755 "archappl" "archappl"''
      ''Z "${cfg.settings.ARCHAPPL_MEDIUM_TERM_FOLDER}" 0755 "archappl" "archappl"''
      ''Z "${cfg.settings.ARCHAPPL_LONG_TERM_FOLDER}"   0755 "archappl" "archappl"''
    ];
  };
}
