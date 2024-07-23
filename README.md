# Installation of idp.access-ci.org on AWS

## Introduction

[idp.access-ci.org](https://idp.access-ci.org/idp/) is a
[Shibboleth Identity Provider
v4.x](https://wiki.shibboleth.net/confluence/display/IDP4/) (IdP) hosted in
[AWS](https://uiuc-xsede-cyberinfrastructure.signin.aws.amazon.com/console)
(Amazon Web Services) infrastructure. The installation is achieved using an
[AWS Reference Architecture for Shibboleth
IdP](https://github.com/aws-samples/aws-refarch-shibboleth), which is a set
of YAML files used to quickly set up and configure a
[CloudFormation](https://aws.amazon.com/cloudformation/) stack of hosts and
networks. This documentation describes the installation and configuration
process in detail so that the Identity Provider can be reproduced and
updated.

For the initial setup of your local development environment and upload of 
IdP secrets, see the [Initial Setup](#initial-setup) section below.

## Install the CloudFormation Stack

Log in to the [AWS
Console](https://uiuc-xsede-cyberinfrastructure.signin.aws.amazon.com/console)
using your XSEDE/ACCESS IAM User account.

In the "Search for services" box at the top of the page, enter
"[CloudFormation](https://us-east-2.console.aws.amazon.com/cloudformation/home?region=us-east-2)".

On the "[Stacks](https://us-east-2.console.aws.amazon.com/cloudformation/home?region=us-east-2#/stacks)"
page, look for stacks named "access-idp-N". (You can toggle
the "View nested" setting to view the root stacks and their child stacks.)

Select one of the links below to create a new stack with an **unused**
stack number.

* [access-idp-1](https://us-east-2.console.aws.amazon.com/cloudformation/home?region=us-east-2#/stacks/quickcreate?templateUrl=https%3A%2F%2Faccess-idp-templates.s3.us-east-2.amazonaws.com%2Faccess-ci-aws-shibboleth-idp.yaml&stackName=access-idp-1)
* [access-idp-2](https://us-east-2.console.aws.amazon.com/cloudformation/home?region=us-east-2#/stacks/quickcreate?templateUrl=https%3A%2F%2Faccess-idp-templates.s3.us-east-2.amazonaws.com%2Faccess-ci-aws-shibboleth-idp.yaml&stackName=access-idp-2)
* [access-idp-3](https://us-east-2.console.aws.amazon.com/cloudformation/home?region=us-east-2#/stacks/quickcreate?templateUrl=https%3A%2F%2Faccess-idp-templates.s3.us-east-2.amazonaws.com%2Faccess-ci-aws-shibboleth-idp.yaml&stackName=access-idp-3)
* [access-idp-4](https://us-east-2.console.aws.amazon.com/cloudformation/home?region=us-east-2#/stacks/quickcreate?templateUrl=https%3A%2F%2Faccess-idp-templates.s3.us-east-2.amazonaws.com%2Faccess-ci-aws-shibboleth-idp.yaml&stackName=access-idp-4)

On the "Quick create stack" page, scroll to the bottom and check the two checkboxes
in the "Capabilities" section, then click the "Create Stack" button.

The CloudFormation stack consists of 6 stacks: the root "access-idp-N"
stack and 5 stacks for Cluster, DeploymentPipeline, LoadBalancer, Service,
and VPC. It can take up to 10 minutes for the root stack to show
`CREATE_COMPLETE` in the stack list.

**But wait! It's not done yet!** After the `access-idp-N` stack shows
`CREATE_COMPLETE`, the Docker image might not yet be built. To check the
progress of the Docker image build, click on the main
`access-idp-N` stack, then click the "Outputs" tab.
Click the PipelineUrl you find there.

On the Pipeline page, you will see 3 phases: Source, Build, and Deploy.
Build will probably still be in progress. Click "Details" to view the
progress. Build takes the longest, but Deploy can also take a couple of
minutes.

**Note**: the rest of the installation instructions below assume the
CloudFormation stack created is named `access-idp-1`.

## Update the Number of Running Instances

There is a bit of a chicken-and-egg problem with CloudFormation stacks in
that the deployment pipeline needs to be working before before the Elastic
Container Services (ECS). So the ECS is initially deployed with 0 running
instances. After the CloudFormation stack deployment is complete, you need
to update the ECS "desired task count" from 0 to 1.

Log in to the [AWS
Console](https://uiuc-xsede-cyberinfrastructure.signin.aws.amazon.com/console)
using your XSEDE/ACCESS IAM User account.

In the "Search for services" box at the top of the page, enter
"[Elastic Container
Service](https://us-east-2.console.aws.amazon.com/ecs/home?region=us-east-2)" or
"ECS".

In the main "Clusters" window, click on the cluster that was created
(e.g., `access-idp-1`). Then click on the Service under the
"Service Name" column (e.g., 
`access-idp-1-Service-JGWEIBGIJEI-FargateService`).  Click the "Update Service"
button. Change the "Desired tasks" to 1, then click the "Update" button.
Back on the "Clusters" page, you should see that the "Tasks" column shows
"1 Pending". Eventually, the "Tasks" column will show "1 Running".

## Test the Newly Deployed Stack

When you install a new stack for the service, you should test to verify that
things are still working correctly before putting the new service in production.
Testing idp.access-ci.org on a given CloudFormation stack is possible since all
interaction with the IdP is initiated by the client (e.g., the user's browser). So
to test a specific instance, you simply need to add an entry in your local
`/etc/hosts` file which points to the stack you want to use.

### Find the Load Balancer DNS Name

Log in to the [AWS
Console](https://uiuc-xsede-cyberinfrastructure.signin.aws.amazon.com/console)
using your XSEDE/ACCESS IAM User account.

In the "Search for services" box at the top of the page, enter
"[CloudFormation](https://us-east-2.console.aws.amazon.com/cloudformation/home?region=us-east-2)".

Locate the root CloudFormation stack that was deployed and click on it.
Note that there are nested stacks, but we are looking for the root stack
named `access-idp-1`. Under the "Outputs" tab, locate the "LoadBalancerDNSName"
entry. Then find the IP address associated with this DNS name using a
command like `host` or `dig`. Example:

```
host acces-loadb-l4tepgtf5fho-328656092.us-east-2.elb.amazonaws.com

acces-loadb-l4tepgtf5fho-328656092.us-east-2.elb.amazonaws.com has address 18.221.40.125
acces-loadb-l4tepgtf5fho-328656092.us-east-2.elb.amazonaws.com has address 18.223.191.147
```

Add one of the IP addresses to your local `/etc/hosts` file. Example:

```
18.221.40.125   idp.access-ci.org
```

Remember to remove this extra line from your local `/etc/hosts` file once
you are finished testing.

### Test ECP Login

You must test ECP (command line) access in order to verify Duo MFA works
with both ECP and web-based clients. ECP testing is performed with the
https://cilogon.org/ecp.pl script. Example:

```
wget https://cilogon.org/ecp.pl
perl ecp.pl --proxyfile --idpname access --certreq create --lifetime 12
    Enter a username for the Identity Provider: <ACCESS Kerberos username>
    Enter a password for the Identity Provider: <ACCESS Kerberos password>
    <You will be prompted to approve an automatic Duo Push.>

openssl x509 -noout -subject -issuer -enddate -in "/tmp/x509up_u${UID}"
    subject= /DC=org/DC=cilogon/C=US/O=ACCESS/CN=ACCESS User A12345
    issuer= /DC=org/DC=cilogon/C=US/O=CILogon/CN=CILogon Silver CA 1
    notAfter=Oct 26 04:41:37 2020 GMT
```

### Test Web Login

Go to https://cilogon.org/testidp/ (preferrably using a single
Private/Incognito browser window) and select "ACCESS CI". Log in with your
ACCESS Kerberos username and password, and verify that you got all of the
User Attributes you expect. 

When you are finished testing, remove the extra line from your `/etc/hosts`
file (or prepend with '#' to comment it out).

## Increase the Number of Running Instances

Once everything is running as expected, increase the number of running
instances from 1 to 2. This will provide load balancing and fail-over in
case of failure of one of the service instances. See 
[Update the Number of Running
Instances](#update-the-number-of-running-instances) above for instructions
on how to do this. It's also a good idea to retest ECP and web browser
login using all of the various IP addresses for the 
[LoadBalancerDNSName](find-the-load-balancer-dns-name).

## Update DNS to the New Stack

Once you are satisfied with the new CloudFormation stack, update the DNS
entry to point to the new stack. 

The DNS entry for `idp.access-ci.org` is a CNAME record managed by NCSA,
which points to `idp.dyn-access-ci.org`. The `dyn-access-ci.org` domain
name is managed by AWS Route 53.

Log in to the [AWS
Console](https://uiuc-xsede-cyberinfrastructure.signin.aws.amazon.com/console)
using your XSEDE/ACCESS IAM User account.

In the "Search for services" box at the top of the page, enter
"[Route 53](https://us-east-1.console.aws.amazon.com/route53)".

In the left column, click "Hosted zones". In the main window, click
on the "dyn-access-ci.org" Domain name.

Check the checkbox next to "idp.dyn-access-ci.org". In the right column, click the
"Edit record" button.

In the right column, click the "X" next to "dualstack.access-ci-loadb-..."
to get a list of available load balancer DNS names. Select the load
balancer corresponding to the DNS name you found earlier (which didn't
have "dualstack" prepended). Then click the "Save" button. It can take a few
minutes for DNS to propagate to your local machine.

## Delete the Previous CloudFormation Stack

**NOTE:** Since DNS clients might be (mis)configured to update the DNS record
for idp.access-ci.org less frequently than asserted by Route 53, it is prudent
to wait at least an hour before deleting the previous CloudFormation stack.

After you have verified that DNS has been updated, you can delete the
previous CloudFormation stack to free up AWS resources (and thus decrease
the monthly bill). Deleting a CloudFormation stack is a bit tricky since
resources are created during the installation process which cannot be
deleted automatically during the top-level "delete stack" operation. So
you will need to begin the delete stack process, and then monitor for
failures. When a sub-stack delete fails, navigate to the stack's
"Resources" tab to see which component failed. Click on the link which
opens a new tab/window for the associated S3 bucket. Check the checkbox
for the offending file/resource, and click Delete. Then try deleting the
top-level CloudFormation stack again. It may require a few tries to
completely delete all of the dynamically created files.

In particular the following stack resources typically require manual deletion.

* DeploymentPipeline
  * Resources:
    * [ArtifactBucket](https://console.aws.amazon.com/s3/home)
    * [ECRRepo](https://us-east-2.console.aws.amazon.com/ecr/repositories/?region=us-east-2)

---

# Update the Shibboleth IdP Stack

When a new Shibboleth IdP Docker image is available, you will need to
update the AWS deployment. In summary, this consists of the following
steps:

1. Get the list of [currently installed CloudFormation
   stacks](https://us-east-2.console.aws.amazon.com/cloudformation/home#/)
   named "access-idp-N".
2. Install a new
   [CloudFormation](https://us-east-2.console.aws.amazon.com/cloudformation/home?region=us-east-2)
   stack with an unused number.
3. Increase the number of running instances to '1'.
4. Test the new stack for both ECP and web browser.
5. Increase the number of running instances to '2'.
6. Test the stack again to make sure ECP works with both instances.
7. Update DNS to point to the new stack.
8. Delete the previous CloudFormation stack.

---

# Maintenance

## View Logs

The build pipeline and Shibboleth IdP software use CloudWatch for logging.

Log in to the [AWS
Console](https://uiuc-xsede-cyberinfrastructure.signin.aws.amazon.com/console)
using your XSEDE/ACCESS IAM User account.

In the "Search for services" box at the top of the page, enter
"[CloudWatch](https://us-east-2.console.aws.amazon.com/cloudwatch/home?region=us-east-2)".

In the left column, select "Log groups".

There are two logs associated with the deployment:

* `/aws/codebuild/access-idp-N` - Logs for building the Dockerfile
* `/ecs/access-idp-N` - Logs for the Shibboleth IdP Tomcat process (e.g.,
  ACCESS user logins)

## Restart the Service

Log in to the [AWS
Console](https://uiuc-xsede-cyberinfrastructure.signin.aws.amazon.com/console)
using your XSEDE/ACCESS IAM User account.

In the "Search for services" box at the top of the page, enter
"[Elastic Container
Service](https://us-east-2.console.aws.amazon.com/ecs/home?region=us-east-2)" or
"ECS".

In the main "Cluster" window,
click on the cluster that was created (e.g., `access-idp-1`). Then click on
the Service under the "Service Name" column (e.g., 
`access-idp-1-Service-JGWEIBGIJEI-FargateService`).  Click the "Update"
button. 

You now have two options.

1. Double the "Number of tasks", then click the "Skip to review" button.
   Then, click the "Update Service" button. Back on the Cluster
   page, you should see that the "Desired tasks" column shows double what
   was shown before. Eventually, the "Running tasks" column will also show
   that number. Then, repeat the process, only this time halve the "Number
   of tasks". ECS will stop the oldest tasks leaving you with just the
   newer tasks. \
   **-- OR --**
2. Check the "Force new deployment" checkbox, then click the "Skip to
   review" button. Then, click the "Update service" button. It will take
   several minutes to restart all of the tasks.

## Update the InCommon SSL Cert

Since the TLS/SSL certificate from InCommon is good for just over a year,
it will need to be updated periodically. In the [Initial
Setup](#initial-setup) instructions below, the first certificate was
requested with the "Enable Auto-Renewal" setting.  When the current
certificate is about to expire, Certificate Services Manager will send an
email to the requesters with a link to a new certificate. Use the
instructions [below](#obtain-a-new-incommon-ssl-cert-for-https) to select the
correct download links for the new certificate and intermediate certificate chain.
Be sure to delete the last (root) certificate from the intermediate certificate
file. Note that you will also need the `idp_access-ci_org.key` file you generated
before.

Log in to the [AWS
Console](https://uiuc-xsede-cyberinfrastructure.signin.aws.amazon.com/console)
using your XSEDE/ACCESS IAM User account.

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

---

# Initial Setup

The Shibboleth Identity Provider (IdP) software relies on several
credentials for functionality. These credentials are generated locally and
then uploaded to the AWS Secrets Manager, where they are used by the
deployed IdP. The following configuration steps are done *before* the
IdP is deployed.


## Get an AWS IAM User Account

In order to work with AWS, you must first have an AWS account which enables
you to log in to the [AWS
Console](https://uiuc-xsede-cyberinfrastructure.signin.aws.amazon.com/console).
The account should be an IAM User
account with AdministratorAccess permissions. This will allow you to create
additional login credentials for deploying the CloudFormation stack and
uploading IdP secrets. Contact JP Navarro
<navarro@mcs.anl.gov> to set up a new AWS user account. Also be sure to
configure MFA on the account (using Google Authenticator style TOTP
codes).

## Install the AWS CLI to Local Development Environment

In order to facilitate the uploading of secrets to AWS, install the AWS CLI
to your local development machine. Instructions are available at 
https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html.
Example:

```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

To run the `aws` command, you will need an AWS Access Key ID and AWS Secret
Access Key.

Log in to the [AWS
Console](https://uiuc-xsede-cyberinfrastructure.signin.aws.amazon.com/console)
using your XSEDE/ACCESS IAM User account.

In the "Search for services" box at the top of the page, enter
"[IAM](https://us-east-1.console.aws.amazon.com/iamv2)". In the
right pane, click "Users". 

On the "Users" page, scroll until you find your name.
You may need to use the `<` / `>` page arrow buttons to see more users
than fit on the current page. Click on your User name.

On the "Summary" page, click on the "Security credentials" tab. Under "Access
keys", click "Create access key". Click the "Show" link to view your "Secret access
key".  Record the "Access key ID" and the "Secret access key". **IMPORTANT**: the
secret is only shown once, so record it in a safe location.

Then run `aws configure` using the values above when prompted. Example:

```
# aws configure
AWS Access Key ID [None]: ABCDEFGHIJKLMNOPQRST
AWS Secret Access Key [None]: abcdefghijklmnopqrstuvwxyz01234567891011
Default region name [None]: us-east-2
Default output format [None]: json
```

Note if you have multiple AWS accounts, you can use 
[Named Profiles for the AWS
CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html#cli-configure-files-using-profiles)
to easily swap between accounts. 

## (Optional) Install Session Manager Plugin

If you need to log in to the running IdP instance for debugging (like
`docker exec -it ... /bin/sh`), you first need to install the [AWS CLI Session
Manager Plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html). 

But this is just the client-side configuration. Changes also need to be made
server-side to enable [ECS
Exec](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-exec.html).
For example, the
[access-ci-service.yaml](https://s3.console.aws.amazon.com/s3/object/access-idp-templates?region=us-east-2&prefix=access-ci-service.yaml)
file must be updated to include the `EnableExecuteCommand` property:

```
  FargateService:
    Type: AWS::ECS::Service
    Condition: Fargate
    Properties:
      EnableExecuteCommand: true
      . . .
```

IAM access permissions may also need to be updated to allow ECS Exec for your
AWS user account. 

## Obtain a New InCommon SSL Cert for HTTPS

The TSL/SSL connection (`https://` on port 443) is secured by an InCommon
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

**IMPORTANT**: Be sure to save the newly generated `idp_access-ci_org.key`
file someplace safe. This file will be needed again for certificate
renewal in one year. The key is available in the NCSA shared LastPass folder
"Shared-security-certauth" in the "ACCESS IDP SSL cert private key" note.

Log in to the [InCommon Certificate Manager](https://cert-manager.com/customer/InCommon). (If you do not have access to
the InCommon Certificate Manager, send the resulting
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

## Upload New InCommon SSL Cert to AWS Certificate Manager

For this step, you will need three of the files from the previous step.

Log in to the [AWS
Console](https://uiuc-xsede-cyberinfrastructure.signin.aws.amazon.com/console)
using your XSEDE/ACCESS IAM User account.

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

## Generate API Key for XDCDB

In order to populate name and email attributes, a query is made to an XDCDB
API endpoint using an API key. Go to the [new XDCDB API
site](https://a3mdev.xsede.org/xdcdb-api-test-new/) and click [Generate
APIKEY](https://a3mdev.xsede.org/xdcdb-api-test-new/api/api_key). This will
generate two new values `API-KEY` and an associated `HASH`. Record the
`API-KEY` for use below, and follow the instructions on the page to send the
`HASH` to [ACCESS
Support](https://support.access-ci.org/user/login?destination=/open-a-ticket).
The "agent" is "ACCESSIDP", and the "resource" is "idp.access-ci.org".
Example email:

```
Subject: ACCESS-API Hash Installation Request

Please install the following HASH for agent "ACCESSIDP" for
resource/hostname "idp.access-ci.org":

    $2a$10$PNCCWKj7QAOrHhZuSfyEPun5.eidIz3EnWMx0MwaehJ/zaeMz9152

on server https://a3mdev.xsede.org/xdcdb-api-test-new/
```

Do NOT send the `API-KEY` in the email. This value is secret and will be
uploaded to the AWS Secrets Manager below.

## 

## Temporarily Install Shibboleth IdP Software

In order to generate the necessary certificates and keys for the IdP software,
do a fresh [install of the Shibboleth
IdP](https://shibboleth.atlassian.net/wiki/x/DgFwSw) software to your local
development box. This step generates credentials to be used by the AWS IdP
installation. The local Shibboleth IdP installation can be deleted later.

When installing locally, enter the values shown below. When you are asked to
enter passwords, note them down, but don't worry too much about them since we
won't need them after the initial setup.

Note: The responses entered by the user are indented in the text below to
improve readability.

```
# bin/install.sh
Source (Distribution) Directory (press <enter> to accept default):
    <ENTER>
Installation Directory: [/opt/shibboleth-idp] ?
    ~/opt/shibboleth-idp
Host Name: [serge.ncsa.illinois.edu] ?
    idp.access-ci.org
Creating idp-signing, CN = idp.access-ci.org URI = https://idp.access-ci.org/idp/shibboleth, keySize=3072
Creating idp-encryption, CN = idp.access-ci.org URI = https://idp.access-ci.org/idp/shibboleth, keySize=3072
Backchannel PKCS12 Password:
    <PASSWORD1>
Re-enter password:
    <PASSWORD1>
Creating backchannel keystore, CN = idp.access-ci.org URI = https://idp.access-ci.org/idp/shibboleth, keySize=3072
Cookie Encryption Key Password:
    <PASSWORD2>
Re-enter password:
    <PASSWORD2>
Creating backchannel keystore, CN = idp.access-ci.org URI = https://idp.access-ci.org/idp/shibboleth, keySize=3072
INFO  - No existing versioning property, initializing...
SAML EntityID: [https://idp.access-ci.org/idp/shibboleth] ?
    https://access-ci.org/idp
Attribute Scope: [access-ci.org] ?
    <ENTER>
. . .
BUILD SUCCESSFUL

```

The resulting credentials are in `~/opt/shibboleth-idp/credentials`. Save
these files for future commands.

The key for the backchannel is stored in the `idp-backchanne.p12` file. We
need to extract it to a PEM-formatted file.

```
openssl pkcs12 -info -in idp-backchannel.p12 -nodes -nocerts | tee idp-backchannel.key
### Enter PASSWORD1 from above
```

## Upload IdP Certs and Keys to AWS Secrets Manager

Now that we have the certificates and keys for the IdP, we need to upload
them to the AWS Secrets Manager. We will use the AWS CLI utility for this
step since special formatting is required.

After each cert/key is uploaded, note the resulting ARNs (AWS Registration
Numbers), which will be used as default values in the
[access-ci-aws-shibboleth-idp.yaml](https://s3.console.aws.amazon.com/s3/object/access-idp-templates?region=us-east-2&prefix=access-ci-aws-shibboleth-idp.yaml) file.

```
export SECRETPREFIX=idp-access-ci-org
export KEY=$(sed -z  's/\n/\\n/g' idp-encryption.key)
export CERT=$(sed -z 's/\n/\\n/g' idp-encryption.crt)
aws secretsmanager create-secret \
    --name "${SECRETPREFIX}-encryption" \
    --description "Encryption certificate and key for idp.access-ci.org" \
    --tags '[{"Key":"WBS","Value":"ACCESS CONECT 1.4"}]' \
    --secret-string '{"key":"'"${KEY}"'","cert":"'"${CERT}"'"}'

export KEY=$(sed -z  's/\n/\\n/g' idp-signing.key)
export CERT=$(sed -z 's/\n/\\n/g' idp-signing.crt)
aws secretsmanager create-secret \
    --name "${SECRETPREFIX}-signing" \
    --description "Signing certificate and key for idp.access-ci.org" \
    --tags '[{"Key":"WBS","Value":"ACCESS CONECT 1.4"}]' \
    --secret-string '{"key":"'"${KEY}"'","cert":"'"${CERT}"'"}'

export KEY=$(sed -z  's/\n/\\n/g' idp-backchannel.key)
export CERT=$(sed -z 's/\n/\\n/g' idp-backchannel.crt)
aws secretsmanager create-secret \
    --name "${SECRETPREFIX}-backchannel" \
    --description "Backchannel certificate and key for idp.access-ci.org" \
    --tags '[{"Key":"WBS","Value":"ACCESS CONECT 1.4"}]' \
    --secret-string '{"key":"'"${KEY}"'","cert":"'"${CERT}"'"}'

export JKS=$(base64 -w 0 sealer.jks)
export PWD=$(grep "^idp.sealer.storePassword" secrets.properties | sed -e 's/.* = //')
aws secretsmanager create-secret \
    --name "${SECRETPREFIX}-sealer-key" \
    --description "The sealer JKS and password for idp.access-ci.org, base64-encoded" \
    --tags '[{"Key":"WBS","Value":"ACCESS CONECT 1.4"}]' \
    --secret-string '{"jks":"'"${JKS}"'","pwd":"'"${PWD}"'"}'

export SALT=$(openssl rand -hex 15)
aws secretsmanager create-secret \
    --name "${SECRETPREFIX}-persistentid-salt" \
    --description "The salt to use for computed / persistent IDs" \
    --tags '[{"Key":"WBS","Value":"ACCESS CONECT 1.4"}]' \
    --secret-string '{"salt":"'"${SALT}"'"}'

export API_KEY=<API-KEY GENERATED FOR XDCDB API ABOVE>
aws secretsmanager create-secret \
    --name "${SECRETPREFIX}-api-key" \
    --description "The API-KEY used when contacting the XDCDB API" \
    --tags '[{"Key":"WBS","Value":"ACCESS CONECT 1.4"}]' \
    --secret-string '{"key":"'"${API_KEY}"'"}'
```

## Obtain a Kerberos Keytab file for HTTP-idp.access-ci.org

The IdP is configured to authenticate users using Kerberos. For this, we need
a keytab file. 

Submit a request at [ACCESS
Support](https://support.access-ci.org/user/login?destination=/open-a-ticket)
asking for a keytab file for service principal
`HTTP/idp.access-ci.org@TERRAGRID.ORG`.  You should get `kadmin` access to
the KDC server. Then generate a local keytab file on a machine with NCSA
kadmin access:

```
kadmin -r TERAGRID.ORG -s kadmin.teragrid.org -p username@TERAGRID.ORG
# Enter your XSEDE password

# Once in kadmin, create the principal:
addprinc -randkey HTTP/idp.access-ci.org@TERAGRID.ORG

# Then generate the keytab file:
ktadd -k HTTP-idp.access-ci.org.keytab HTTP/idp.access-ci.org@TERAGRID.ORG

exit
```

The resulting keytab file is `./HTTP-idp.access-ci.org.keytab`.

## Upload the Kerberos Keytab file to AWS Secrets Manager

```
export SECRETPREFIX=idp-access-ci-org
export KEYTAB=$(base64 -w 0 HTTP-idp.access-ci.org.keytab)
aws secretsmanager create-secret \
    --name "${SECRETPREFIX}-HTTP-keytab" \
    --description "The krb5.keytab file for idp.access-ci.org, base64-encoded" \
    --tags '[{"Key":"WBS","Value":"ACCESS CONECT 1.4"}]' \
    --secret-string '{"keytab":"'"${KEYTAB}"'"}'
```

After the keytab file is uploaded, note the ARN (AWS Registration Number).
This will be used as the default value in the 
[access-ci-aws-shibboleth-idp.yaml](https://s3.console.aws.amazon.com/s3/object/access-idp-templates?region=us-east-2&prefix=access-ci-aws-shibboleth-idp.yaml) file.

## Obtain Duo Application Secrets

The IdP uses Duo as a second authentication factor. Several new
Duo "Applications" must be created and the resulting keys uploaded to AWS.

Submit a request at [ACCESS
Support](https://support.access-ci.org/user/login?destination=/open-a-ticket)
asking for 3 new Duo Applications:

```
Application 1
Type: Shibboleth
Name: idp.access-ci.org Shib

Application  2
Type: Auth API
Name: idp.access-ci.org ECP

Application 3
Type: Web SDK
Name idp.access-ci.org
```

These should be configured similarly to the existing idp.xsede.org
Applications. 

Next, generate two [application
keys](https://duo.com/docs/duoweb-v2#1.-generate-an-akey) for the browser
and non-browser (ECP) flows. These are values that are kept secret from Duo
and should be at least 40 characters long.

```
export B_APP_KEY=$(openssl rand -hex 20)
export E_APP_KEY=$(openssl rand -hex 20)
echo "browser_app_key = ${B_APP_KEY}"
echo "ecp_app_key = ${E_APP_KEY}"

```

Record the resulting secrets/keys in a text file `ACCESS-Duo.txt`. (Note
that the values below are not the actual keys.)

```
idp.access-ci.org Shib (Shibboleth)
browser_app_key = abcdefghijklmnopqrstuvwxyz01234567890101
browser_int_key = DEFGHIJKLMNOPQRSTUVW
browser_sec_key = xyz0123456789101abcdefghijklmnopqrstuvwx
browser_api_host = api-12345678.duosecurity.com

idp.access-ci.org ECP (Auth API)
ecp_app_key = bcdefghijklmnopqrstuvwxyz0123456789abcde
ecp_int_key = EFGHIJKLMNOPQRSTUVWX
ecp_sec_key = 7890101abcdefghijklmnopqrstuvwxyz0123456
ecp_api_host = api-12345678.duosecurity.com

idp.access-ci.org (Web SDK)
oidc_int_key = FGHIJKLMNOPQRSTUVWXY
oidc_sec_key = pqrstuvwxyz0123456789010abcdefghijklmnop
oidc_api_host = api-12345678.duosecurity.com

```

## Upload the Duo Application Secrets to AWS Secrets Manager

Using the file `ACCESS-Duo.txt` created above, use the AWS CLI to
upload them to the AWS Secrets Manager. 

```
export SECRETPREFIX=idp-access-ci-org
export B_APP=$(grep "^browser_app_key" ACCESS-Duo.txt | sed -e 's/.* = //')
export B_INT=$(grep "^browser_int_key" ACCESS-Duo.txt | sed -e 's/.* = //')
export B_SEC=$(grep "^browser_sec_key" ACCESS-Duo.txt | sed -e 's/.* = //')
export E_APP=$(grep "^ecp_app_key" ACCESS-Duo.txt | sed -e 's/.* = //')
export E_INT=$(grep "^ecp_int_key" ACCESS-Duo.txt | sed -e 's/.* = //')
export E_SEC=$(grep "^ecp_sec_key" ACCESS-Duo.txt | sed -e 's/.* = //')
export O_INT=$(grep "^oidc_int_key" ACCESS-Duo.txt | sed -e 's/.* = //')
export O_SEC=$(grep "^oidc_sec_key" ACCESS-Duo.txt | sed -e 's/.* = //')
aws secretsmanager create-secret \
    --name "${SECRETPREFIX}-duo-settings" \
    --description "The keys for Duo MFA" \
    --tags '[{"Key":"WBS","Value":"ACCESS CONECT 1.4"}]' \
    --secret-string \
    '{"browser_app_key":"'"${B_APP}"'","browser_int_key":"'"${B_INT}"'","browser_sec_key":"'"${B_SEC}"'","ecp_app_key":"'"${E_APP}"'","ecp_int_key":"'"${E_INT}"'","ecp_sec_key":"'"${E_SEC}"'","oidc_int_key":"'"${O_INT}"'","oidc_sec_key":"'"${O_SEC}"'"}'
```

After the Duo secrets are uploaded, note the ARN (AWS Registration Number).
This will be used as the default value in the 
[access-ci-aws-shibboleth-idp.yaml](https://s3.console.aws.amazon.com/s3/object/access-idp-templates?region=us-east-2&prefix=access-ci-aws-shibboleth-idp.yaml) file.

## Upload Templates and Code to AWS S3

There are 6 YAML template files used by [AWS
CloudFormation](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/)
to create the resources needed for the IdP. Additionally, there is one ZIP
file containing the Dockerfile needed to build the Docker image, as well as
configuration files stored in the Docker image. These files need to be
uploaded to a new AWS S3 bucket for access by AWS CloudFormation.

The files are:

* access-ci-aws-shibboleth-idp.yaml
* access-ci-deployment-pipeline.yaml
* access-ci-ecs-cluster.yaml
* access-ci-load-balancer.yaml
* access-ci-service.yaml
* access-ci-vpc.yaml
* code.zip

The main AWS CloudFormation template file is
`access-ci-aws-shibboleth-idp.yaml`. The other template files are
referenced by this file. This template file also contains the "Default"
ARNs for the certificates and secrets uploaded to the AWS Secrets Manager
above.

Log in to the [AWS
Console](https://uiuc-xsede-cyberinfrastructure.signin.aws.amazon.com/console)
using your XSEDE/ACCESS IAM User account.

In the "Search for services" box at the top of the page, enter "[S3](https://s3.console.aws.amazon.com/s3/home?region=us-east-2)".

On the "Buckets" page, click "Create bucket".

For "Bucket name" enter `access-idp-templates`. **UN**check "Block all
public access". Then click "Create bucket".

To upload the YAML templates and the `code.zip` file to the new
`access-idp-templates` bucket, use the AWS CLI.

```
for i in *.yaml ; do aws s3 cp "${i}" s3://access-idp-templates/ ; done
aws s3 cp code.zip s3://access-idp-templates/
```

## Sign Up for Shibboleth IdP Updates

To be informed of updates to the [Shibboleth IdP
Docker](https://hub.docker.com/r/i2incommon/shib-idp/tags) container image,
[log in to the InCommon Trusted Access Platform
Release page](https://spaces.at.internet2.edu/login?target=%2Fpages%2Fviewpage.action%3FspaceKey%3DITAP%26title%3DInCommon%2BTrusted%2BAccess%2BPlatform%2BRelease&os_destination=%2Fdisplay%2FITAP%2FInCommon%2BTrusted%2BAccess%2BPlatform%2BRelease)
using your University IdP, and click the "(Eye) Watch" icon at the top
right of the page. You will get emails when anything on that page is
updated. The Shibboleth IdP Docker Container is the package to monitor.

To be informed of updates to the [Shibboleth IdP
software](https://shibboleth.atlassian.net/wiki/x/CgFwSw) and related plugins, sign
up for the [Shibboleth Announce](https://shibboleth.net/mailman/listinfo/announce)
mailing list.

---

# Notes

## Source Configuration Files

The configuration (yaml) files used for setting up the XSEDE IdP
CloudFormation stack resides in an S3 bucket
'[access-idp-templates](https://s3.console.aws.amazon.com/s3/buckets/access-idp-templates/)'.
These templates are modified versions of the [AWS Reference Architecture for
Shibboleth IdP](https://github.com/aws-samples/aws-refarch-shibboleth)
configuration files:

* [access-ci-aws-shibboleth-idp.yaml](https://s3.console.aws.amazon.com/s3/object/access-idp-templates?region=us-east-2&prefix=access-ci-aws-shibboleth-idp.yaml)
* [access-ci-deployment-pipeline.yaml](https://s3.console.aws.amazon.com/s3/object/access-idp-templates?region=us-east-2&prefix=access-ci-deployment-pipeline.yaml)
* [access-ci-ecs-clulster.yaml](https://s3.console.aws.amazon.com/s3/object/access-idp-templates?region=us-east-2&prefix=access-ci-ecs-cluster.yaml)
* [access-ci-load-balancer.yaml](https://s3.console.aws.amazon.com/s3/object/access-idp-templates?region=us-east-2&prefix=access-ci-load-balancer.yaml)
* [access-ci-service.yaml](https://s3.console.aws.amazon.com/s3/object/access-idp-templates?region=us-east-2&prefix=access-ci-service.yaml)
* [access-ci-vpc.yaml](https://s3.console.aws.amazon.com/s3/object/access-idp-templates?region=us-east-2&prefix=access-ci-vpc.yaml)
* [code.zip](https://s3.console.aws.amazon.com/s3/object/access-idp-templates?region=us-east-2&prefix=code.zip)

Of these files, `code.zip` may need to be updated when a new version of the
[Shibboleth IdP Software](https://shibboleth.atlassian.net/wiki/x/CgFwSw)
is released, due to configuration file changes.
If so, download `code.zip`, make changes as necessary, and re-upload the
file to the S3 bucket. Files in the S3 bucket are version controlled, so
you can revert to a previous version if necessary. After a new `code.zip`
file has been uploaded, you will need to redeploy the stack (using a new
stack number) to read the updated configuration files.

## AWS Components

The following AWS componenets are used by the CloudFormation stack.

* [CloudFormation](https://us-east-2.console.aws.amazon.com/cloudformation/home#/)
  - root of the services stack
* [CloudWatch](https://us-east-2.console.aws.amazon.com/cloudwatch/home#logsV2:log-groups)
  - 2 Log Groups (`/aws/codebuild/access-idp-1` and
  `/ecs/access-idp-1`)
* [CodeBuild](https://us-east-2.console.aws.amazon.com/codesuite/codebuild/projects)
* [CodeCommit](https://us-east-2.console.aws.amazon.com/codesuite/codecommit/repositories)
  - `access-idp-1` repository
* [CodePipeline](https://us-east-2.console.aws.amazon.com/codesuite/codepipeline/pipelines)
* [EC2 Container
  Registry](https://us-east-2.console.aws.amazon.com/ecr/repositories)
  (ECR)
* [EC2 container
  Service](https://us-east-2.console.aws.amazon.com/ecs/home#/clusters)
  (ECS) for Fargate - 2vCPUs, 4GB memory
* [Elastic Load
  Balancer](https://us-east-2.console.aws.amazon.com/ec2/v2/home#LoadBalancers:)
  (ELB) - 1 application
* [Key Management Service](https://us-east-2.console.aws.amazon.com/kms/home#/kms/defaultKeys)
* [Route 53](https://us-east-2.console.aws.amazon.com/route53/v2/home) - DNS for `idp.dyn-access-ci.org`
* [Secrets Manager](https://us-east-2.console.aws.amazon.com/secretsmanager/home#/listSecrets)
* [Simple Store Service](https://console.aws.amazon.com/s3/home) (S3) -
  storage for YAML scripts and repos
* [Virtual Private
  Cloud](https://us-east-2.console.aws.amazon.com/vpc/home#vpcs:) (VPC) - 2
  public subnets, 2 private subnets

## AWS CLI Commands

While it's probably easier to interact with the AWS Console, many of the
actions can be done using the AWS CLI utility. You will need to install the
[jq](https://stedolan.github.io/jq/) utility, version 1.6 or higher.

### Get ARN for SSL Certificate

```
aws acm list-certificates |
    jq '.CertificateSummaryList[] |
        select(.DomainName == "idp.access-ci.org") |
        .CertificateArn' |
    sed -e 's/^"//' -e 's/"$//'
```

### Get ARNs for Secrets

```
aws secretsmanager list-secrets |
    jq '.SecretList[] |
        select (.Name | test ("^idp-access-ci-org-")) |
        .ARN' |
    sed -e 's/^"//' -e 's/"$//'
```

### Update an Existing Secret Value

Example update of the existing XDCDB API\_KEY:
```
export SECRET_ARN=`aws secretsmanager list-secrets |
       jq '.SecretList[] |
       select (.Name | test ("^idp-access-ci-org-api-key")) |
       .ARN' |
       sed -e 's/^"//' -e 's/"$//'`
export API_KEY=<NEW XDCDB API-KEY>
aws secretsmanager update-secret \
    --secret-id "${SECRET_ARN}" \
    --secret-string '{"key":"'"${API_KEY}"'"}'
```

### List Existing CloudFormation Stacks

```
aws cloudformation list-stacks |
    jq '.StackSummaries[] |
        select (.StackName | test ("^access-idp-\\d$")) |
        select (.StackStatus == "CREATE_COMPLETE") |
        .StackName' |
    sed -e 's/^"//' -e 's/"$//'
```

### Update Number of Running Instances

```
export STACK_NAME=access-idp-1
export DESIRED=1

cluster=`aws ecs list-clusters |
    jq '.clusterArns[]' |
    sed -e 's/^"//' -e 's/"$//' |
    grep "${STACK_NAME}"` &&
service=`aws ecs list-services --cluster "${cluster}" |
    jq '.serviceArns[]' |
    sed -e 's/^"//' -e 's/"$//'` &&
aws ecs update-service --cluster "${cluster}" --service "${service}" --desired-count ${DESIRED}
```

### Force Service Restart

```
export STACK_NAME=access-idp-1

cluster=`aws ecs list-clusters |
    jq '.clusterArns[]' |
    sed -e 's/^"//' -e 's/"$//' |
    grep "${STACK_NAME}"` &&
service=`aws ecs list-services --cluster "${cluster}" |
    jq '.serviceArns[]' |
    sed -e 's/^"//' -e 's/"$//'` &&
aws ecs update-service --cluster "${cluster}" --service "${service}" --force-new-deployment
```

### Find the Load Balancer DNS Name

```
export STACK_NAME=access-idp-1

lbstack=`aws cloudformation list-stacks |
    jq '.StackSummaries[] |
        select (.StackName | test("'${STACK_NAME}'-LoadBalancer-")) |
        select (.StackStatus == "CREATE_COMPLETE") |
        .StackName' |
    sed -e 's/^"//' -e 's/"$//'` &&
dnsname=`aws cloudformation describe-stacks --stack-name "${lbstack}" |
    jq '.Stacks[].Outputs[] |
        select (.OutputKey == "DNSName") |
        .OutputValue' |
    sed -e 's/^"//' -e 's/"$//'` &&
echo "dualstack.${dnsname}" | tr '[:upper:]' '[:lower:]'
```

## Working with the CodeCommit Repository

During the CloudFormation stack creation, a new CodeCommit repository was
created. The repo has the configuration files used by the Shibboleth IdP
(i.e., `code.zip`). If you want to make immediate, short-term changes to
configuration (e.g., for testing purposes), you can clone the repository,
make changes, and push the changes to the repo. This will trigger a new
Deployment Pipeline build/deploy.

To clone the repo, log in to the [AWS
Console](https://uiuc-xsede-cyberinfrastructure.signin.aws.amazon.com/console)
using your XSEDE/ACCESS IAM User account.

In the "Search for services" box at the top of the page, enter
"[IAM](https://us-east-1.console.aws.amazon.com/iamv2)". In the
right pane, click "Users". 

On the "Users" page, scroll until you find your name.
You may need to use the `<` / `>` page arrow buttons to see more users
than fit on the current page. Click on your User name.

On the "Summary" page, click on the "Security credentials" tab. Under
"HTTPS Git credentials for AWS CodeCommit", click the "Generate
credentials" button. You will be shown a popup window with a new "User
name" and "Password". Click the "Show" link to show your "Password". Record
these values somewhere safe. The password will not be shown again. This
user name and password are used for [HTTPS git operations with
CodeCommit](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_ssh-keys.html#git-credentials-code-commit). 

In the "Search for services" box at the top of the page, enter
"[CodeCommit](https://us-east-2.console.aws.amazon.com/codesuite/codecommit/home?region=us-east-2)".

In the repository list page, click the "HTTPS" link for the
"access-idp-1" repo, which will be used for a `git clone URL` operation.

Alternatively, you can clone the repo with the AWS CLI as follows.

```
export STACK_NAME=access-idp-1

url=`aws codecommit get-repository --repository-name "${STACK_NAME}" | 
    jq '.repositoryMetadata.cloneUrlHttp' |
    sed -e 's/^"//' -e 's/"$//'` && git clone $url
```

Make any changes you want to the configuration files in the `access-idp-1`
directory. Then commit those changes and push them back to the CodeCommit
repo. This will trigger a new Deployment Pipeline build/deploy. Example:

```
export STACK_NAME=access-idp-1

cd "${STACK_NAME}"
echo >> Dockerfile
git commit -am "Trigger service re-build/deploy"
git push -u origin main
```

You can watch the new build/deploy operation on the
[CodePipeline](https://us-east-2.console.aws.amazon.com/codesuite/codepipeline/pipelines)
page corresponding to `access-idp-1`.

**NOTE**: changes made to the CodeCommit repo affect only the currently
running instance. If you want to make longer-term changes, update the
configuration files in the `code.zip` file and deploy a new instance of the
CloudFormation stack.

