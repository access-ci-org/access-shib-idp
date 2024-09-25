FROM i2incommon/shib-idp:latest5

ARG AWS_DEFAULT_REGION
ARG AWS_ACCESS_KEY_ID
ARG AWS_SECRET_ACCESS_KEY
ARG AWS_SESSION_TOKEN
ARG PARENT_DOMAIN
ARG FULLY_QUALIFIED_DOMAIN_NAME
ARG SECRETS_MANAGER_SIGNING_ARN
ARG SECRETS_MANAGER_BACKCHANNEL_ARN
ARG SECRETS_MANAGER_ENCRYPTION_ARN
ARG SECRETS_MANAGER_SEALER_KEY_ARN
ARG SECRETS_MANAGER_HTTP_KEYTAB_ARN
ARG SECRETS_MANAGER_PERSISTENTID_SALT_ARN
ARG SECRETS_MANAGER_DUO_SETTINGS_ARN
ARG SECRETS_MANAGER_XDCDB_API_KEY_ARN

COPY config/shib-idp /opt/shibboleth-idp
COPY config/tomcat   /usr/local/tomcat

# Add the AWS Java SDK to the IdP webapp
RUN echo "Adding the AWS SDK for Java"; \
    mkdir -p /tmp/aws-java-sdk-installation && \
    cd /tmp/aws-java-sdk-installation && \
    wget -q https://sdk-for-java.amazonwebservices.com/latest/aws-java-sdk.zip && \
    unzip -q -o aws-java-sdk.zip && \
    rm aws-java-sdk-*/lib/aws-java-sdk-*-javadoc.jar && \
    rm aws-java-sdk-*/lib/aws-java-sdk-*-sources.jar && \
    cp aws-java-sdk-*/lib/aws-java-sdk-*.jar /opt/shibboleth-idp/edit-webapp/WEB-INF/lib/ && \
    cd ~ && \
    rm -rf /tmp/aws-java-sdk-installation

# Install AWS CLI
RUN echo "Installing the AWS CLI"; \
    mkdir -p /tmp/aws-cli-installation && \
    cd /tmp/aws-cli-installation && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install -i /usr/local/aws -b /usr/local/bin && \
    cd ~ && \
    rm -rf /tmp/aws-cli-installation

# Install jq
ENV JQ_VERSION='1.7'
RUN wget --no-check-certificate https://raw.githubusercontent.com/stedolan/jq/master/sig/jq-release-new.key -O /tmp/jq-release-new.key && \
    wget --no-check-certificate https://raw.githubusercontent.com/stedolan/jq/master/sig/v${JQ_VERSION}/jq-linux-amd64.asc -O /tmp/jq-linux-amd64.asc && \
    wget --no-check-certificate https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64 -O /tmp/jq-linux64 && \
    gpg --import /tmp/jq-release-new.key && \
    gpg --verify /tmp/jq-linux-amd64.asc /tmp/jq-linux64 && \
    cp /tmp/jq-linux64 /usr/bin/jq && \
    chmod +x /usr/bin/jq && \
    rm -f /tmp/jq-release-new.key && \
    rm -f /tmp/jq-linux-amd64.asc && \
    rm -f /tmp/jq-linux64

# Install openssl
RUN yum -y install openssl

# Install the new Duo OIDC-based prompt
RUN /opt/shibboleth-idp/bin/plugin.sh -I net.shibboleth.oidc.common \
    && /opt/shibboleth-idp/bin/plugin.sh -I net.shibboleth.idp.plugin.authn.duo.nimbus \
    && rm -f /opt/shibboleth-idp/conf/authn/duo-oidc.properties

# Grab the signing key and cert from secrets manager and save them as needed
RUN signing=`aws --region "${AWS_DEFAULT_REGION}" secretsmanager get-secret-value --secret-id "${SECRETS_MANAGER_SIGNING_ARN}" --query 'SecretString' | sed -e 's/^"//' -e 's/"$//'` && \
    echo $signing | sed -e 's/\\"/"/g' | jq '.key' | sed -e 's/^"//' -e 's/"$//' -e 's/\\\\n/\n/g' > /opt/shibboleth-idp/credentials/idp-signing.key && \
    echo $signing | sed -e 's/\\"/"/g' | jq '.cert' | sed -e 's/^"//' -e 's/"$//' -e 's/\\\\n/\n/g' > /opt/shibboleth-idp/credentials/idp-signing.crt && \
    cert=$(echo $signing | sed -e 's/\\"/"/g' | jq '.cert' | sed -e 's/^"//' -e 's/"$//' -e 's/\\\\n/\\n/g' -e 's/-*BEGIN CERTIFICATE-*\\n//' -e 's/\\n-*END CERTIFICATE-*\\n//') && \
    sed -i "s|XXXX-SigningPublicCert-XXXX|$cert|g" /opt/shibboleth-idp/metadata/idp-metadata.xml

# Grab the backchannel key and cert from secrets manager and save them as needed
RUN backchannel=`aws --region "${AWS_DEFAULT_REGION}" secretsmanager get-secret-value --secret-id "${SECRETS_MANAGER_BACKCHANNEL_ARN}" --query 'SecretString' | sed -e 's/^"//' -e 's/"$//'` && \
    echo $backchannel | sed -e 's/\\"/"/g' | jq '.key' | sed -e 's/^"//' -e 's/"$//' -e 's/\\\\n/\n/g' > /opt/shibboleth-idp/credentials/idp-backchannel.key && \
    echo $backchannel | sed -e 's/\\"/"/g' | jq '.cert' | sed -e 's/^"//' -e 's/"$//' -e 's/\\\\n/\n/g' > /opt/shibboleth-idp/credentials/idp-backchannel.crt && \
    cert=$(echo $backchannel | sed -e 's/\\"/"/g' | jq '.cert' | sed -e 's/^"//' -e 's/"$//' -e 's/\\\\n/\\n/g' -e 's/-*BEGIN CERTIFICATE-*\\n//' -e 's/\\n-*END CERTIFICATE-*\\n//') && \
    sed -i "s|XXXX-BackchannelPublicCert-XXXX|$cert|g" /opt/shibboleth-idp/metadata/idp-metadata.xml

# Grab the encryption key and cert from secrets manager and save them as needed
RUN encryption=`aws --region "${AWS_DEFAULT_REGION}" secretsmanager get-secret-value --secret-id "${SECRETS_MANAGER_ENCRYPTION_ARN}" --query 'SecretString' | sed -e 's/^"//' -e 's/"$//'` && \
    echo $encryption | sed -e 's/\\"/"/g' | jq '.key' | sed -e 's/^"//' -e 's/"$//' -e 's/\\\\n/\n/g' > /opt/shibboleth-idp/credentials/idp-encryption.key && \
    echo $encryption | sed -e 's/\\"/"/g' | jq '.cert' | sed -e 's/^"//' -e 's/"$//' -e 's/\\\\n/\n/g' > /opt/shibboleth-idp/credentials/idp-encryption.crt && \
    cert=$(echo $encryption | sed -e 's/\\"/"/g' | jq '.cert' | sed -e 's/^"//' -e 's/"$//' -e 's/\\\\n/\\n/g' -e 's/-*BEGIN CERTIFICATE-*\\n//' -e 's/\\n-*END CERTIFICATE-*\\n//') && \
    sed -i "s|XXXX-EncryptionPublicCert-XXXX|$cert|g" /opt/shibboleth-idp/metadata/idp-metadata.xml

# Grab the seaker JKS and password from secrets manager
RUN sealer=`aws --region "${AWS_DEFAULT_REGION}" secretsmanager get-secret-value --secret-id "${SECRETS_MANAGER_SEALER_KEY_ARN}" --query 'SecretString' | sed -e 's/^"//' -e 's/"$//'` && \
    sealer_pwd=$(echo $sealer | sed -e 's/\\"/"/g' | jq '.pwd' | sed -e 's/^"//' -e 's/"$//') && \
    sealer_jks=$(echo $sealer | sed -e 's/\\"/"/g' | jq '.jks' | sed -e 's/^"//' -e 's/"$//') && \
    sed -i "s|XXXX-SealerPassword-XXXX|$sealer_pwd|g" /opt/shibboleth-idp/conf/idp.properties && \
    echo $sealer_jks | base64 -d > /opt/shibboleth-idp/credentials/sealer.jks && \
    chmod 660 /opt/shibboleth-idp/credentials/sealer.jks

# Replace domain names in IdP config files with proper domains
RUN sed -i "s|XXXX-ParentDomain-XXXX|$PARENT_DOMAIN|g" /opt/shibboleth-idp/conf/idp.properties && \
    sed -i "s|XXXX-FullyQualifiedDomainName-XXXX|$FULLY_QUALIFIED_DOMAIN_NAME|g" /opt/shibboleth-idp/conf/idp.properties && \
    sed -i "s|XXXX-ParentDomain-XXXX|$PARENT_DOMAIN|g" /opt/shibboleth-idp/metadata/idp-metadata.xml && \
    sed -i "s|XXXX-FullyQualifiedDomainName-XXXX|$FULLY_QUALIFIED_DOMAIN_NAME|g" /opt/shibboleth-idp/metadata/idp-metadata.xml

# Grab the persistentId salt from the secrets manager
RUN salt_settings=`aws --region "${AWS_DEFAULT_REGION}" secretsmanager get-secret-value --secret-id "${SECRETS_MANAGER_PERSISTENTID_SALT_ARN}" --query 'SecretString' | sed -e 's/^"//' -e 's/"$//'` && \
    salt=$(echo $salt_settings | sed -e 's/\\"/"/g' | jq '.salt' | sed -e 's/^"//' -e 's/"$//') && \
    sed -i "s|XXXX-PersistentIDSalt-XXXX|$salt|g" /opt/shibboleth-idp/conf/saml-nameid.properties

# Grab Duo client_secrets from the secrets manager
RUN duo_settings=`aws --region "${AWS_DEFAULT_REGION}" secretsmanager get-secret-value --secret-id "${SECRETS_MANAGER_DUO_SETTINGS_ARN}" --query 'SecretString' | sed -e 's/^"//' -e 's/"$//'` && \
    ecp_app_key=$(echo $duo_settings | sed -e 's/\\"/"/g' | jq '.ecp_app_key' | sed -e 's/^"//' -e 's/"$//') && \
    ecp_int_key=$(echo $duo_settings | sed -e 's/\\"/"/g' | jq '.ecp_int_key' | sed -e 's/^"//' -e 's/"$//') && \
    ecp_sec_key=$(echo $duo_settings | sed -e 's/\\"/"/g' | jq '.ecp_sec_key' | sed -e 's/^"//' -e 's/"$//') && \
    oidc_int_key=$(echo $duo_settings | sed -e 's/\\"/"/g' | jq '.oidc_int_key' | sed -e 's/^"//' -e 's/"$//') && \
    oidc_sec_key=$(echo $duo_settings | sed -e 's/\\"/"/g' | jq '.oidc_sec_key' | sed -e 's/^"//' -e 's/"$//') && \
    sed -i "s|XXXX-ECPApplicationKey-XXXX|$ecp_app_key|g" /opt/shibboleth-idp/conf/authn/duo.properties && \
    sed -i "s|XXXX-ECPIntegrationKey-XXXX|$ecp_int_key|g" /opt/shibboleth-idp/conf/authn/duo.properties && \
    sed -i "s|XXXX-ECPSecretKey-XXXX|$ecp_sec_key|g" /opt/shibboleth-idp/conf/authn/duo.properties && \
    sed -i "s|XXXX-OIDCIntegrationKey-XXXX|$oidc_int_key|g" /opt/shibboleth-idp/conf/authn/duo.properties && \
    sed -i "s|XXXX-OIDCSecretKey-XXXX|$oidc_sec_key|g" /opt/shibboleth-idp/conf/authn/duo.properties

# Grab the ACCESS-CI krb5.keytab file from the secrets manager
RUN httpkeytab=`aws --region "${AWS_DEFAULT_REGION}" secretsmanager get-secret-value --secret-id "${SECRETS_MANAGER_HTTP_KEYTAB_ARN}" --query 'SecretString' | sed -e 's/^"//' -e 's/"$//'` && \
    echo $httpkeytab | sed -e 's/\\"/"/g' | jq '.keytab' | sed -e 's/^"//' -e 's/"$//' | \
    base64 -d > /opt/shibboleth-idp/credentials/HTTP-idp.access-ci.org.keytab && \
    chmod 660 /opt/shibboleth-idp/credentials/HTTP-idp.access-ci.org.keytab

# Grab the XDCDB API Key from the secrets manager
RUN xdcdbapikey=`aws --region "${AWS_DEFAULT_REGION}" secretsmanager get-secret-value --secret-id "${SECRETS_MANAGER_XDCDB_API_KEY_ARN}" --query 'SecretString' | sed -e 's/^"//' -e 's/"$//'` && \
    apikey=$(echo $xdcdbapikey | sed -e 's/\\"/"/g' | jq '.key' | sed -e 's/^"//' -e 's/"$//') && \
    sed -i "s|XXXX-XDCDBAPIKey-XXXX|$apikey|g" /opt/shibboleth-idp/conf/attribute-resolver.xml
