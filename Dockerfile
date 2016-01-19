FROM registry.camunda.com/camunda-ci-base-centos:latest

# Set environment variables for WebSphere
ENV JDK_VERSION=8u66-b17/jdk-8u66-linux-x64.rpm \
    WLS_PKG_FILE=fmw_12.2.1.0.0_wls_quick_Disk1_1of1.zip \
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
    DISPLAY=:0 \
    DISPLAY_WIDTH=1366 \
    DISPLAY_HEIGHT=768 \
    DISPLAY_DEPTH=16
ENV JAVA_OPTIONS "-Djava.security.egd=file:/dev/./urandom\ -XX:+PrintCommandLineFlags"

RUN add-path.sh $WLS_BIN_DIR

RUN save-env.sh WLS_INSTALL_HOME WLS_HOME WLS_DOMAIN_HOME WLS_SERVER WLS_ADMIN_USERNAME WLS_ADMIN_PASSWORD WLS_HTTP_PORT WLS_HTTPS_PORT WLS_DEBUG_PORT CONFIG_JVM_ARGS USER_MEM_ARGS JAVA_OPTIONS DISPLAY DISPLAY_WIDTH DISPLAY_HEIGHT DISPLAY_DEPTH
RUN echo 'export JAVA_DEBUG="-Xdebug -Xnoagent -Xrunjdwp:transport=dt_socket,address=${WLS_DEBUG_PORT},server=y,suspend=n -Djava.compiler=NONE"' >> /etc/profile.d/env.sh
RUN echo 'export USER_MEM_ARGS="-Xms768m -Xmx768m -XX:PermSize=256m -XX:MaxPermSize=256m"' >> /etc/profile.d/env.sh
RUN install-oracle-jdk.sh http://download.oracle.com/otn-pub/java/jdk/$JDK_VERSION

# update certs for JDK 8 keystore
RUN update-ca-trust enable && \
    $JAVA_HOME/bin/keytool -noprompt -keystore $JAVA_HOME/jre/lib/security/cacerts -storepass changeit -import -trustcacerts -v -alias ldap_camunda_com -file /etc/pki/ca-trust/source/anchors/ldap_camunda_com.crt && \
    $JAVA_HOME/bin/keytool -noprompt -keystore $JAVA_HOME/jre/lib/security/cacerts -storepass changeit -import -trustcacerts -v -alias nginx_consul -file /etc/pki/ca-trust/source/anchors/nginx_consul.crt && \
    update-ca-trust extract

# add google-chrome repo
ADD /etc/yum.repos.d/* /etc/yum.repos.d/
# install packages for ui
RUN install-packages.sh xvfb x11vnc google-chrome-stable
# fix dbus error which prevents chrome from starting
RUN dbus-uuidgen > /etc/machine-id

# Add supervisor configs
ADD etc/supervisor.d/* /etc/supervisord.d/

ADD bin/* /usr/local/bin/
ADD etc/oracle/weblogic-response-file.txt $WLS_RESPONSE_FILE
ADD etc/oracle/create-wls-domain.py /home/camunda/

# Install WebLogic as camunda users
RUN su camunda -c /usr/local/bin/install-weblogic.sh
# Create Weblogic domain
RUN su camunda -c /usr/local/bin/create-wls-domain.sh
# Create symlink to log
RUN su camunda -c "ln -s --target-directory=/home/camunda ${WLS_DOMAIN_HOME}/servers/${WLS_SERVER}/logs/${WLS_SERVER}.log"

# expose weblogic and vnc ports
EXPOSE 5900 $WLS_HTTP_PORT $WLS_HTTPS_PORT $WLS_DEBUG_PORT
