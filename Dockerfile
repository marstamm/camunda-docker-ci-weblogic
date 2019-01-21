FROM gcr.io/ci-30-162810/chrome:64v0.2.0

# Set environment variables for WebSphere
ENV WLS_PKG_FILE=fmw_12.2.1.0.0_wls_quick_Disk1_1of1.zip \
    WLS_INSTALL_FILE=fmw_12.2.1.0.0_wls_quick.jar \
    WLS_INSTALL_HOME=/home/camunda/oracle/ \
    WLS_HOME=/home/camunda/oracle/wlserver/ \
    WLS_DOMAIN_HOME=/home/camunda/oracle/domains/base_domain/ \
    WLS_BIN_DIR=/home/camunda/oracle/oracle_common/common/bin \
    WLS_SERVER=AdminServer \
    WLS_ADMIN_USERNAME=weblogic \
    WLS_ADMIN_PASSWORD=weblogic1 \
    WLS_HTTP_PORT=7001 \
    WLS_HTTPS_PORT=7002 \
    WLS_DEBUG_PORT=8787 \
    CONFIG_JVM_ARGS=-Djava.security.egd=file:/dev/./urandom \
    USER_MEM_ARGS="-Xms768m -Xmx768m -XX:PermSize=256m -XX:MaxPermSize=256m" \
    JAVA_HOME=/usr/java/default \
    JAVA_OPTIONS="-Djava.security.egd=file:/dev/./urandom\ -XX:+PrintCommandLineFlags" \
    JDK_VERSION=8u112

RUN add-path.sh ${WLS_BIN_DIR}
RUN save-env.sh WLS_INSTALL_HOME WLS_HOME WLS_DOMAIN_HOME WLS_SERVER WLS_ADMIN_USERNAME WLS_ADMIN_PASSWORD WLS_HTTP_PORT WLS_HTTPS_PORT WLS_DEBUG_PORT CONFIG_JVM_ARGS JAVA_OPTIONS JAVA_HOME
RUN echo 'export JAVA_DEBUG="-Xdebug -Xnoagent -Xrunjdwp:transport=dt_socket,address=${WLS_DEBUG_PORT},server=y,suspend=n -Djava.compiler=NONE"' >> /etc/profile.d/env.sh
RUN echo -n "export USER_MEM_ARGS=\"${USER_MEM_ARGS}\"" >> /etc/profile.d/env.sh

RUN gsutil cp gs://camunda-ops/binaries/oracle/jdk/jdk-${JDK_VERSION}-linux-x64.rpm /tmp/jdk.rpm && \
    rpm -ivh /tmp/jdk.rpm && \
    rm /tmp/jdk.rpm

# update certs for JDK 8 keystore
RUN update-ca-trust enable && \
    ${JAVA_HOME}/bin/keytool -noprompt -keystore ${JAVA_HOME}/jre/lib/security/cacerts -storepass changeit -import -trustcacerts -v -alias ldap_camunda_com -file /etc/pki/ca-trust/source/anchors/ldap_camunda_com.crt && \
    update-ca-trust extract

COPY etc/supervisor.d/* /etc/supervisord.d/
COPY bin/* /usr/local/bin/
COPY etc/oracle/create-wls-domain.py /home/camunda/

RUN su camunda -c /usr/local/bin/install-weblogic.sh && \
    clean-caches.sh && \
    # Fix corrupt weblogic jar files by deleting  broken JAR index files which prevent invoice example from being deployed because of InvalidJarIndexException during Java 8 Nashorn classloading
    su camunda -c "zip -d ${WLS_INSTALL_HOME}/oracle_common/modules/oracle.xdk/xmlparserv2_sans_jaxp_services.jar 'META-INF/INDEX.LIST'" && \
    su camunda -c "zip -d ${WLS_INSTALL_HOME}/oracle_common/modules/mysql-connector-java-commercial-5.1.22/mysql-connector-java-commercial-5.1.22-bin.jar 'META-INF/INDEX.LIST'"

RUN su camunda -c /usr/local/bin/create-wls-domain.sh && \
    # Create symlink to log
    su camunda -c "ln -s --target-directory=/home/camunda ${WLS_DOMAIN_HOME}/servers/${WLS_SERVER}/logs/${WLS_SERVER}.log"

EXPOSE ${WLS_HTTP_PORT} ${WLS_HTTPS_PORT} ${WLS_DEBUG_PORT}
