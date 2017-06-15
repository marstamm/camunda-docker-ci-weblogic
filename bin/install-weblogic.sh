#!/usr/bin/env bash
set -e

WLS_TEMP=/tmp/wls

echo "Retrieving installation files"
gsutil cp gs://camunda-ops/binaries/oracle/weblogic/${WLS_PKG_FILE} /tmp/${WLS_PKG_FILE}

mkdir -p ${WLS_TEMP} ${WLS_INSTALL_HOME}
# do some repairing. something doesn't work with zip and pkzip format
zip -FFv /tmp/${WLS_PKG_FILE} --out /tmp/${WLS_PKG_FILE}.fixed && unzip -q /tmp/${WLS_PKG_FILE}.fixed -d ${WLS_TEMP}
java -jar ${WLS_TEMP}/${WLS_INSTALL_FILE} ORACLE_HOME=${WLS_INSTALL_HOME}
rm -rf /tmp/${WLS_PKG_FILE}* ${WLS_TEMP}

# Clean caches
clean-caches.sh
