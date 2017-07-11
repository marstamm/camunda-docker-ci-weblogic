FROM gcr.io/ci-30-162810/chrome:v0.1.0

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
    WLS_RESPONSE_FILE=/home/camunda/weblogic-response-file.txt \
    WLS_HTTP_PORT=7001 \
    WLS_HTTPS_PORT=7002 \
    WLS_DEBUG_PORT=8787 \
    CONFIG_JVM_ARGS=-Djava.security.egd=file:/dev/./urandom \
    GCLOUD=/opt/google-cloud-sdk/bin \
    JAVA_HOME=/usr/java/default \
    JAVA_OPTIONS="-Djava.security.egd=file:/dev/./urandom\ -XX:+PrintCommandLineFlags"

RUN add-path.sh $WLS_BIN_DIR $GCLOUD
RUN save-env.sh WLS_INSTALL_HOME WLS_HOME WLS_DOMAIN_HOME WLS_SERVER WLS_ADMIN_USERNAME WLS_ADMIN_PASSWORD WLS_HTTP_PORT WLS_HTTPS_PORT WLS_DEBUG_PORT CONFIG_JVM_ARGS USER_MEM_ARGS JAVA_OPTIONS JAVA_HOME
RUN echo 'export JAVA_DEBUG="-Xdebug -Xnoagent -Xrunjdwp:transport=dt_socket,address=${WLS_DEBUG_PORT},server=y,suspend=n -Djava.compiler=NONE"' >> /etc/profile.d/env.sh
RUN echo 'export USER_MEM_ARGS="-Xms768m -Xmx768m -XX:PermSize=256m -XX:MaxPermSize=256m"' >> /etc/profile.d/env.sh

RUN $GCLOUD/gsutil cp gs://camunda-ops/binaries/oracle/jdk/jdk-8u112-linux-x64.rpm /tmp/jdk8.rpm && \
    rpm -ivh /tmp/jdk8.rpm && \
    rm /tmp/jdk8.rpm

# update certs for JDK 8 keystore
RUN update-ca-trust enable && \
    $JAVA_HOME/bin/keytool -noprompt -keystore $JAVA_HOME/jre/lib/security/cacerts -storepass changeit -import -trustcacerts -v -alias ldap_camunda_com -file /etc/pki/ca-trust/source/anchors/ldap_camunda_com.crt && \
    update-ca-trust extract

# Add supervisor configs
ADD etc/supervisor.d/* /etc/supervisord.d/

ADD bin/* /usr/local/bin/
ADD etc/oracle/weblogic-response-file.txt $WLS_RESPONSE_FILE
ADD etc/oracle/create-wls-domain.py /home/camunda/

# Install WebLogic as camunda users
RUN su camunda -c /usr/local/bin/install-weblogic.sh && \
    clean-caches.sh

# Fix corrupt weblogic jar files
RUN su camunda -c /usr/local/bin/fix-weblogic.sh

# Create Weblogic domain
RUN su camunda -c /usr/local/bin/create-wls-domain.sh

# Create symlink to log
RUN su camunda -c "ln -s --target-directory=/home/camunda ${WLS_DOMAIN_HOME}/servers/${WLS_SERVER}/logs/${WLS_SERVER}.log"

# expose weblogic and vnc ports
EXPOSE $WLS_HTTP_PORT $WLS_HTTPS_PORT $WLS_DEBUG_PORT
