#!/usr/bin/env bash
set -e

BASE_DOMAIN_HOME=${WLS_INSTALL_HOME}/domains/base_domain

${WLS_INSTALL_HOME}/oracle_common/common/bin/wlst.sh -skipWLSModuleScanning /home/camunda/create-wls-domain.py && \
    mkdir -p ${BASE_DOMAIN_HOME}/servers/AdminServer/security && \
    echo "username=${WLS_ADMIN_USERNAME}" > ${BASE_DOMAIN_HOME}/servers/AdminServer/security/boot.properties && \
    echo "password=${WLS_ADMIN_PASSWORD}" >> ${BASE_DOMAIN_HOME}/servers/AdminServer/security/boot.properties && \

echo ". ${BASE_DOMAIN_HOME}/bin/setDomainEnv.sh" >> /home/camunda/.bashrc && \
echo "export PATH=${PATH}:${WLS_INSTALL_HOME}/wlserver/common/bin:${BASE_DOMAIN_HOME}/bin" >> /home/camunda/.bashrc