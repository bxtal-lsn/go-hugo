# Hashicorp Vault Guide
Hashicorp Vault is a secrets management tool that securely stores, controls access to, and distributes sensitive information such as API keys, passwords, and certificates.  
It provides a unified interface for any secret, with fine-grained access control policies and detailed audit logs.  
Vault features dynamic secret generation for temporary credentials, automatic key rotation, encryption as a service, and various authentication methods including LDAP, JWT, and cloud provider integrations.  
It can be deployed in high-availability configurations with built-in support for data replication.  
Vault uses a key-value store model with versioning capabilities and offers both UI and API interfaces.  
Organizations use Vault to centralize secrets management, enforce security practices, and reduce the risk of credentials leakage in infrastructure, applications, and CI/CD pipelines.

## Install Hashicorp Vault

Install Hashicorp Vault according to your Linux OS.  
See installation guides [here](https://developer.hashicorp.com/vault/install)

perhaps just download, unzip, and move vault executable to /usr/local/bin/

## Configure Vault

If not exists 
```bash
mkdir /etc/vault.d/
```  
If not exists 
```bash
mkdir /opt/vault/data/
```  
Then make sure group vault has correct permissions 
```bash
sudo chown -R vault:vault /opt/vault/data
```  
Set the vault address env variable 
```bash
export VAULT_ADDR=http://127.17.0.1:8200
```

An initial config file could look something like this:  
```hcl
storage "raft" {
  path = "/opt/vault/data"
  node_id = "vault_node_a"
}

# HTTP listener
listener "tcp" {
  address = "0.0.0.0:8200"
  cluster_address = "0.0.0.0:8201"
  tls_disable = 1
}

api_addr = "http://172.17.0.1:8200"
cluster_addr = "http://172.17.0.1:8201"
cluster_name = "demo_cluster"
log_level = "INFO"
```

Start and enable vault service 
```bash
sudo systemctl enable --now vault
```  
For debugging use 
```bash
sudo systemctl status vault
``` 
or 
```bash
sudo journalctl -xeu vault.service
```

Run 
```bash
vault status
``` 
to see if everything is in order  

## Vault Initialization
```bash
vault operator init
```
Now the vault instance is initialized, but still sealed.  
The only way to access the vault instance is to use the Initial Root Token, which should be deleted after the rbac and other initial security and logins are finished.  
The Initial Root Token is never rotated and has highest privilege access to all secrets in vault.

## Unseal Methods

### 1. Unsealing with unseal keys

Unseal keys are stored in ~/hashicorp/vault/ for dev purposes.

Default is set to 5 unseal keys and the threshold is 3 for unsealing the vault.  

Input 3 unseal keys here, three times

```bash
vault operator unseal
```

after this is done, confirm that the Sealed Value is `False` now. 

```bash
vault status
```

Now you can log in with the initial root token, which was grabbed when initializing the vault.

```bash
vault login
```

```bash
vault secrets list
```

```bash
vault auth list
```

### 2. Unsealing with auto-unseal

If the vault is unsealed, restart it to test auto-unseal.  
```bash
sudo systemctl restart vault
```

run `vault status` to check if the Value of Sealed is `True`.



To completely reset the vault instance, stop the service 
```bash
sudo systemctl stop vault
```

go to
```bash
cd /opt/vault/data
```

reset the vault
```bash
sudo rm vault.db
sudo rm -r raft/
```

Add auto-unseal to vault.hcl
This example is with awskms
```bash
sudo vim /etc/vault.d/vault.hcl
```

Add this to the file
```bash
seal "awskms" {
  region = "<region>"
  kms_key_id = "kms_key_id"
}
```

restart the service `sudo systemctl start vault`

This should be displayed in `vault status` Key type should be awskms.

then run 
```bash
vault operator init
```

Now there are not seal keys anymore, but recovery keys,  
and now in `vault status` the Sealed state should be `False`, because it has been auto unsealed.

if you run 
```bash
sudo systemctl restart vault 
```

Then the vault should be in an unsealed state automatically.

### 3. Unsealing with Transit Auto-Unseal
-- TODO
no info on this?

## Vault Tokens

create a token with root priveleges
```bash
vault token create
```

use the token id value to inspect the token
```bash
vault token lookup <token id>
```

to revoke the token use
```bash
vault token revoke <token id>
```

to create a token with default policy with default ttl and so on, use
```bash
vault token create -policy=bartal
```

to customize it, use 
```bash
vault token create -policy=bartal2 -ttl=1h - orphan
```

to renew the above token so it starts at 1h again, run 
```bash
vault token renew
```
also note the option to set max_ttl.

## Authentication Methods
look at current auths
```bash
vault auth list
```

enable auth
```bash
vault auth enable userpass
```

write new user
```bash
vault write auth/userpass/users/vault-user password=vault123 policies=devops
```

confirm user creation 
```bash
vault list auth/userpass/users
vault read auth/userpass/users/vault-user
```

log into vault with root token
```bash
vault token lookup
```

grab the id and run 
```bash
vault login <id>
```

login as vault-user
```bash
vault login -method=userpass username=vault-user
```
Then you will be prompted for the password. now you are logged in and can see your info and your token.

to see the policies for `devops` policy run
```bash
vault policy read devops
```

check auths again
```bash
vault auth list
```

create authentication for approle. What is approle?
should perhaps when logged in as root?
```bash
vault auth enable approle
```

run `vault auth list` again.

```bash
vault policy write cloud policy.hcl
```

create role
```bash
vault write auth/approle/role/team-cloud token_ttl=20m token_max_ttl=1h policies=cloud
```

list approles
```bash
vault list auth/approle/role
```

```bash
vault read auth/approle/role/team-cloud
```

also add devops to approle
```bash
vault write auth/approle/role/devops policies=devops token_ttl=4h token_max_ttl=24h
```

list all approles
```bash
vault list auth/approle/role
```

details about devops
```bash
vault read auth/approle/role/devops
```

get role id
```bash
vault read auth/approle/role/team-cloud/role-id
```

write secret id to team-cloud
```bash
vault write -f auth/approle/team-cloud/secret-id
```

## Audit Devices
Use audit devices to log events in the Vault ecosystem, typcially written to disk as JSON,  
then ingested to a larger log system like DataDog or Prometheus.  

To list audit devices run `vault audit list`, there should currently be none listed.  
Create a file audit device woth `vault audit enable file file_path=/opt/vault/audit.log`
Check if the audit device was created with `vault audit list` or a more detailed view with `vault audit list --detailed`

View the log, preferrably with a tool like jq as such `sudo cat /opt/vault/audit.log | jq`

## Secrets Engine
Secrets Engines are ways to handle secrets, a secrets engine can be a K/V secrets engine or a database secrets engine.  

List secrets with 
```bash
vault secrets list
```

enable a secrets engine like this, this is the aws secrets engine
```bash
vault secrets enable aws
```

list the vault secrets to verify that it is created.  

create a aws secret like this
```bash
vault write aws/config/root \
access_key=<access_key> | secret_key=<secret_key> \
region=us-east-1
```

read the secret with 
```bash
vault read aws/config/root
```

A s3 secret is written like this
```bash
vault write aws/roles/s3fullaccess \
credential_type=iam_user \
policy_arns=<policy_arns>
```

list the aws roles 
```bash
vault list aws/roles
```

read a specific role 
```bash
vault read aws/roles/s3fullaccess
```

read the s3 credentials
```bash
vault read aws/creds/s3fullaccess
```

## K/V Secrets Engine
Engine for storing Key / Value pairs
There are two types of K/V secrets engines, kv1 and kv2  
kv1 overwrites the value pair if modified  
kv2 saves the history of modified k/v pairs  

to enable kv1 run
```bash
vault secrets engine -path=kv1 kv
```

Check if the kv1 is created 
```bash
vault secrets list
```

Write a secret to kv1
```bash
vault kv put kv1/secrets/cloud bartal=larsson cloud=aws db_password=12345
```

Get the secret
```bash
vault kv get kv1/secrets/cloud
```

Add a new secret (because this is kv1 this overwrites the previous secrets, this would not be the case with kv2)
```bash
vault kv put kv1/secrets/cloud url=https://myapp:8080
```

To add secrets engine kv2 and track history
```bash
vault secrets enable -path=kv2 -version=2 kv
```

confirm with 
```bash
vault secrets list --detailed
```

The method for putting secrets is the same as kv1
```bash
vault kv put kv2/my-secret password=mypassword
```

if you overwrite the secret now, a version history is retained

To get a certain version of the secret, then use the -version flag
```bash
vault kv get -version=5 kv2/my-secret
```

to rollback to a previous version use
```bash
vault kv rollback -version=1 kv2/my-secret
```

to delete a version use `delete -versions=1` and versions is pluaral

to permananetly delete use the `destroy -versions=1`

## Database Secrets Engine
Database secrets engines can interact with specific databases such as mysql  
and mssql. They can create static and dynamic secrets.

to initialize the database secrets engine run
```bash
vault secrets enable database
```

create secret for mysql database
```bash
vault write database/config/mysql-db \
plugin_name=mysql-rds-datbase-plugin \
connection_url="{{username}}:{{password}}@tcp(dbstring)/" \
username="vault_admin"
password="Vault123#"
```

confirm database secret creation
```bash
vault list database/config
```

Details about the specific mysql secret
```bash
vault read database/config/mysql-db
```

add role access to the secret
```bash
vault write database/config/mysql-db allowed_roles="app1"
```

Read the details about the secret and confirm the role

configure the role for `app1` role
```bash
vault write /database/roles/app1 \
db_name=mysql-db \
default_ttl="4h" \
max_ttl="24h" \
creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';"
```

read the role
```bash
vault read database/roles/app1
```

read role credentials
```bash
vault read database/creds/app1
```

revoke
```bash
vault lease revoke database/creds/app1/<lease_id>
```

```bash
vault lease revoke prefix=database/
```
