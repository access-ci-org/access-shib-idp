# Old InCommon SSL/TLS Certificate Information

:warning: DEPRECATED :warning:

[idp.access-ci.org](https://idp.access-ci.org/idp) previously used an InCommon
SSL/TLS certificate for the `https://` connection. However, due to the 
[news](https://www.sectigo.com/47-day-ssl) that certificate lifetimes would be
drastically cut over the next few years, an Amazon certificate is now used.
The Amazon certificate is managed by AWS and updated automatically.  Since the
certificate is tied to the Load Balancer, the IdP service does not need to be
restarted upon certificate refresh.

This document preserves the old InCommon SSL/TLS Certificate setup
instructions, but they are no longer needed for the current deployment.

## Updating the InCommon SSL Cert

Since the TLS/SSL certificate from InCommon is good for just over a year,
it will need to be updated periodically. In the [Initial
Setup](#initial-setup) instructions below, the first certificate was
requested with the "Enable Auto-Renewal" setting.  When the current
certificate is about to expire, Certificate Services Manager will send an
email to the requesters with a link to a new certificate. Use the
instructions [below](#obtain-a-new-incommon-ssl-cert-for-https) to select the
correct download links for the new certificate and intermediate certificate
chain.  Be sure to delete the last (root) certificate from the intermediate
certificate file. Note that you will also need the `idp_access-ci_org.key`
file you generated before which was stored in the [AWS Secrets
Manager](https://us-east-2.console.aws.amazon.com/secretsmanager/listsecrets?region=us-east-2)
as `idp-access-ci-org-ssl-key`. (Hint: Click "Retrieve secret value" to view
the `idp_access-ci_org.key` file. Also see [AWS CLI
Commands](#aws-cli-commands) below for a command line version of downloading
the `idp_acess-ci_org.key` file.)

Log in to the [AWS
Console](https://uiuc-access-cyberinfrastructure.signin.aws.amazon.com/console)
using your ACCESS IAM User account.

In the "Search for services" box at the top of the page, enter "[Certificate
Manager](https://us-east-2.console.aws.amazon.com/acm/home?region=us-east-2)".

On the Certificates page, click on the Certificate ID corresponding to the
idp.access-ci.org Domain name, then click the "Reimport" button.

Paste the contents of three files into the text boxes.

* `idp_access-ci_org.crt` goes into "Certificate body".
* `idp_access-ci_org.key` goes into "Certificate private key".
* `intermediate.crt goes` into "Certificate chain".

Then click "Reimport certificate".

Note that the ARN (AWS Registration Number) for the new TLS/SSL certificate
remains unchanged.

## Obtaining a New InCommon SSL/TLS Cert for HTTPS

The TLS/SSL connection (`https://` on port 443) is secured by an InCommon
certificate.

First, generate a new certificate signing request (CSR).

```
openssl req \
        -nodes \
        -newkey rsa:2048 \
        -keyout idp_access-ci_org.key \
        -subj "/CN=idp.access-ci.org/emailAddress=help+idp@ncsa.illinois.edu" \
        -out idp_access-ci_org.csr
```

**IMPORTANT**: Save the newly generated `idp_access-ci_org.key`
file some place safe on your local filesystem. We will upload this key file to
the Secrets Manager [below](#upload-idp-certs-and-keys-to-aws-secrets-manager)
since this file will be needed for certificate renewal in one year.

Log in to the [InCommon Certificate
Manager](https://cert-manager.com/customer/InCommon). (If you do not have
access to the InCommon Certificate Manager, send the resulting
`idp_access-ci_org.csr` to help+idp@ncsa.illinois.edu asking for a new
"InCommon SSL (SHA-2)" certificate.)

Once you are logged in, select the "Hamburger" menu -> Certificates ->
SSL Certificates.

Click the "+" (Add) button in the upper right corner.

1. Initial "Request SSL Certificate" Page:
   select "Using a Certificate Signing Request (CSR)",
   then click "Next".
2. "Details" step:
   * Organization: University of Illinois (default)
   * Department: NCSA (default)
   * Certificate Profile: InCommon SSL (SHA-2)
   * Certificate Term: 398 Days
   * External Requesters: help+idp@ncsa.illinois.edu
   then click "Next".
3. "CSR" step: Paste `idp_access-ci_org.csr` into CSR field, then click
   "Next".
4. "Domains" step: Common Name should be auto-filled with "idp.access-ci.org",
   then click "Next".
5. "Auto-renewal" step: Turn on "Enable Auto-Renewal" slider, renew 30 days
   prior to expiration, then click "OK".

Wait a few minutes to get an email like "Enrollment Successful - Your SSL
certificate for idp.access-ci.org is ready". In that email there are several
download links.

1. Select "Certificate only, PEM encoded" to download the certificate. Example:

```
curl -o 'idp_access-ci_org.crt' 'https://cert-manager.com/customer/InCommon/ssl?action=download&sslId=2026192&format=x509CO'
```

2. Select "Intermediate(s)/Root only, PEM encoded" to download the cert chain.
   Example:

```
curl -o 'intermediate.crt' 'https://cert-manager.com/customer/InCommon/ssl?action=download&sslId=2026192&format=x509IOR'
```

3. Edit `intermediate.crt` to remove the last certificate in the file
(including the `-----BEGIN CERTIFICATE-----` and `-----END CERTIFICATE-----`
lines) since it is a root CA already present in web browers.

## Uploading New InCommon SSL Cert to AWS Certificate Manager

For this step, you will need three of the files from the previous step.

Log in to the [AWS
Console](https://uiuc-access-cyberinfrastructure.signin.aws.amazon.com/console)
using your ACCESS IAM User account.

In the "Search for services" box at the top of the page, enter "[Certificate
Manager](https://us-east-2.console.aws.amazon.com/acm/home?region=us-east-2)".

On the Certificates page, click the "Import" button.

Paste the contents of three files into the text boxes.

* `idp_access-ci_org.crt` goes into "Certificate body".
* `idp_access-ci_org.key` goes into "Certificate private key".
* `intermediate.crt goes` into "Certificate chain".

Then click "Next".

For tags, enter key="WBS" value="ACCESS CONECT 1.4", then click "Next", then
click "Review and import", then click "Import".

On the Certificates page, click the Certificate ID corresponding to the
idp.access-ci.org Domain name.

Under Certificate status, note the ARN (AWS Registration Number) for the
new idp.access-ci.org certificate. This will be used as the default value
in the
[access-ci-aws-shibboleth-idp.yaml](https://s3.console.aws.amazon.com/s3/object/access-idp-templates?region=us-east-2&prefix=access-ci-aws-shibboleth-idp.yaml) file.

## Uploading Key for SSL/TLS Cert to Secrets Manager

```
export KEY=$(sed -z  's/\n/\\n/g' idp_access-ci_org.key)
aws secretsmanager create-secret \
    --name "${SECRETPREFIX}-ssl-key" \
    --description "Key for SSL/TLS certificate for idp.access-ci.org" \
    --tags '[{"Key":"WBS","Value":"ACCESS CONECT 1.4"}]' \
    --secret-string '{"key":"'"${KEY}"'"}'
```

## Downloading `idp_access-ci_org.key` File for Updating the SSL/TLS Certificate

```
aws secretsmanager get-secret-value --secret-id idp-access-ci-org-ssl-key |
    jq -r '.SecretString' |
    jq -r '.key' > idp_access-ci_org.key
```


