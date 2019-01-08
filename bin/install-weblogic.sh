#!/bin/bash
set -euxo pipefail

declare -r GOOGLE_STORAGE_BUCKET=camunda-ops
declare -r WLS_TEMP_DIR=/tmp/wls

function main() {
    echo "Download installation files"
    gsutil cp gs://${GOOGLE_STORAGE_BUCKET}/binaries/oracle/weblogic/${WLS_PKG_FILE} /tmp/${WLS_PKG_FILE}

    mkdir -p ${WLS_TEMP_DIR} ${WLS_INSTALL_HOME}

    # do some repairing. something doesn't work with zip and pkzip format
    zip -FFv /tmp/${WLS_PKG_FILE} --out /tmp/${WLS_PKG_FILE}.fixed && unzip -q /tmp/${WLS_PKG_FILE}.fixed -d ${WLS_TEMP_DIR}

    ${JAVA_HOME}/bin/java -jar ${WLS_TEMP_DIR}/${WLS_INSTALL_FILE} -ignoreSysPrereqs ORACLE_HOME=${WLS_INSTALL_HOME}

    rm -rf /tmp/${WLS_PKG_FILE}* ${WLS_TEMP_DIR}
}

main
