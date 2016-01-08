# Script partly based on %ORACLE_HOME%/wlserver/common/templates/scripts/wlst/basicWLSDomain.py

# WebLogic Default Domain
admin_port = int(os.environ.get("WLS_HTTP_PORT"))
admin_user = os.environ.get("WLS_ADMIN_USERNAME")
admin_pass = os.environ.get("WLS_ADMIN_PASSWORD")
wls_home = os.environ.get("WLS_HOME")
domain_home = os.environ.get("WLS_DOMAIN_HOME")

deploy_target = 'AdminServer'
# jndiName = 'jdbc/ProcessEngine'
# dsName = 'ProcessEngineDS'
# jdbc_driver = 'com.h2database.H2Driver'
# jdbc_url = 'jdbc://localhost:3306/process-engine'
# jdbc_user = 'camunda'
# jdbc_password = 'camunda'
# jdbc_host = 'localhost'  # or engine for db2
# jdbc_port = '3306'  # or engine for db2
# jdbc_databaseName = 'engine'  # or engine for db2
# enable_xa = False
# jdbc_global_tx = 'TwoPhaseCommit'
# jdbc_global_tx = 'OnePhaseCommit'

# Create and configure a JDBC Data Source, and sets the JDBC user
# ===============================================================
def createDatasource(dsName, jndiName, driver, url, user, password, host, port, databaseName, globalTx, xa, deploy_target):
    if not xa:
        print 'YES, NO XA!'

    cd('/')
    sysRes = create(dsName, 'JDBCSystemResource')

    cd('/JDBCSystemResource/' + dsName + '/JdbcResource/' + dsName)
    dataSourceParams = create('dataSourceParams', 'JDBCDataSourceParams')
    dataSourceParams.setGlobalTransactionsProtocol(globalTx)  # TwoPhaseCommit
    cd('JDBCDataSourceParams/NO_NAME_0')
    set('JNDIName', java.lang.String(jndiName))

    cd('/JDBCSystemResource/' + dsName + '/JdbcResource/' + dsName)
    connPoolParams = create('connPoolParams', 'JDBCConnectionPoolParams')
    connPoolParams.setInitialCapacity(10)
    connPoolParams.setMinCapacity(10)
    connPoolParams.setMaxCapacity(30)

    cd('/JDBCSystemResource/' + dsName + '/JdbcResource/' + dsName)
    driverParams = create('driverParams', 'JDBCDriverParams')
    driverParams.setUrl(url)
    driverParams.setDriverName(driver)
    # enc_pw = encrypt(password)
    # print 'Encrypted PW: ' + enc_pw
    # driverParams.setEncryptedPassword(enc_pw)
    driverParams.setUseXaDataSourceInterface(enable_xa)
    driverParams.setPasswordEncrypted(password)
    cd('JDBCDriverParams/NO_NAME_0')

    create(dsName, 'Properties')
    cd('Properties/NO_NAME_0')

    dbUser = create('user', 'Property')
    dbUser.setValue(user)

    dbPassword = create('password', 'Property')
    dbPassword.setValue(password)

    dbName = create('databaseName', 'Property')
    dbName.setValue(databaseName)

    serverName = create('serverName', 'Property')
    serverName.setValue(host)

    portNumber = create('portNumber', 'Property')
    portNumber.setValue(port)

    driverType = create('driverType', 'Property')
    driverType.setValue('4')

    cd('/')
    assign('JDBCSystemResource', dsName, 'Target', target)

    print 'Datasource ' + dsName + ' has been created successfully.'


def createJMSResource(deploy_target):
    jms_server = 'myJMSServer'
    # Create a JMS Server
    # ===================
    cd('/')
    create(jms_server, 'JMSServer')

    # Create a JMS System resource
    # ============================
    cd('/')
    create('myJmsSystemResource', 'JMSSystemResource')
    cd('JMSSystemResource/myJmsSystemResource/JmsResource/NO_NAME_0')

    # Create a JMS Queue and its subdeployment
    # ========================================
    myq=create('myQueue','Queue')
    myq.setJNDIName('jms/myqueue')
    myq.setSubDeploymentName('myQueueSubDeployment')

    cd('/JMSSystemResource/myJmsSystemResource')
    create('myQueueSubDeployment', 'SubDeployment')

    cd('/')
    assign('JMSServer', jms_server, 'Target', deploy_target)
    assign('JMSSystemResource.SubDeployment', 'myJmsSystemResource.myQueueSubDeployment', 'Target', jms_server)


# Open default domain template
# ======================
readTemplate(wls_home + "/common/templates/wls/wls.jar")

# Configure the Administration Server and SSL port.
# =========================================================
cd('Servers/AdminServer')
# listen to all interfaces
set('ListenAddress', '')
set('ListenPort', admin_port)

create('AdminServer','SSL')
cd('SSL/AdminServer')
set('Enabled', 'True')
set('ListenPort', (admin_port + 1))

# Define the user password for weblogic
# =====================================
cd('/')
cd('Security/base_domain/User/' + admin_user)
cmo.setPassword(admin_pass)

# createDatasource(dsName, jndiName, jdbc_driver, jdbc_url, jdbc_user, jdbc_password, jdbc_host, jdbc_port, jdbc_databaseName, jdbc_global_tx, enable_xa, deploy_target)
createJMSResource(deploy_target)

# Write the domain and close the domain template
# ==============================================
setOption('OverwriteDomain', 'true')
setOption('ServerStartMode','dev')  # or 'prod'

cd('/')
cd('NMProperties')
set('ListenAddress','')
set('ListenPort',5556)
set('NativeVersionEnabled', 'false')
set('StartScriptEnabled', 'false')
set('SecureListener', 'false')

# Set the Node Manager user name and password
cd('/')
cd('SecurityConfiguration/base_domain')
set('NodeManagerUsername', admin_user)
set('NodeManagerPasswordEncrypted', admin_pass)

writeDomain(domain_home)

closeTemplate()

exit()
