#!/usr/bin/env bash

# delete broken JAR index files which prevent invoice example from being deployed because of InvalidJarIndexException during Java 8 Nashorn classloading.
zip -d ${WLS_INSTALL_HOME}/oracle_common/modules/oracle.xdk/xmlparserv2_sans_jaxp_services.jar "META-INF/INDEX.LIST"
zip -d ${WLS_INSTALL_HOME}/oracle_common/modules/mysql-connector-java-commercial-5.1.22/mysql-connector-java-commercial-5.1.22-bin.jar "META-INF/INDEX.LIST"