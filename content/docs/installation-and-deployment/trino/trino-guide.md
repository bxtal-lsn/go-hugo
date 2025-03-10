# Trino Guide
Trino (formerly PrestoSQL) is a distributed SQL query engine designed for analyzing large datasets across multiple data sources.  
It enables fast, interactive queries on data where it resides without moving it into a separate analytics system.  
Trino features a coordinator/worker architecture that parallelizes queries across distributed nodes, supports connectivity to diverse data sources (HDFS, object storage, relational databases, NoSQL systems) through connectors, and provides ANSI SQL compatibility with extensions.  
It separates compute from storage, allowing elastic scaling of query processing independent of data location.  
Trino includes cost-based optimization, supports both batch and interactive workloads, and offers authentication mechanisms including LDAP and Kerberos.  
Organizations use Trino for data lake analytics, federated queries across multiple systems, and as a unified query layer for data mesh architectures where high-performance SQL access across heterogeneous data platforms is required.

## Install Temuri JDK 22

Add Eclipse Temurin PPA
```bash
sudo apt update
sudo apt install wget apt-transport-https
wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public | sudo apt-key add -
```

Add Adoptium repo
```bash
echo "deb https://packages.adoptium.net/artifactory/deb focal main" | sudo tee /etc/apt/sources.list.d/adoptium.list
```

Update apt
```bash
sudo apt update
```

Install temurin 22 jdk
```bash
sudo apt install temurin-22-jdk
```
check java version
```bash
java -version
```

should show something like
openjdk version "22" 2024-03-19
OpenJDK Runtime Environment Temurin-22+ (build 22.0.0+36)
OpenJDK 64-Bit Server VM Temurin-22+ (build 22.0.0+36, mixed mode)

Set default java version if many installed
```bash
sudo update-alternatives --config java
```
select preferred version, in this case temurin 22  

set java home dir

```bash
sudo update-alternatives --config java
```

shell config file
```bash
export JAVA_HOME=/usr/lib/jvm/temurin-22-jdk-amd64
export PATH=$JAVA_HOME/bin:$PATH
```
apply changes
```bash
source ~/.bashrc
```

## Install Trino v461

update
```bash
sudo apt update
```

make sure python command is accessible, needs to be python, not python 3.
```bash
sudo ln -s /usr/bin/python3 /usr/bin/python
```

Download trino tar.gz
```bash
wget --no-check-certificate  https://repo1.maven.org/maven2/io/trino/trino-server/461/trino-server-461.tar.gz
```

unpack the tar.gz file
```bash
tar xvzf trino-server-461.tar.gz
```

## Install Trino CLI  

make user bin folder if not exists
```bash
cd
mkdir bin
```
Go to Trino folder
```bash
cd trino-server-461
```
download cli tool
```bash
wget -O trino https://repo.maven.apache.org/maven2/io/trino/trino-cli/461/trino-cli-461-executable.jar
```
modify to get execution permissions
```bash
chmod +x trino
```
Move trino to user's bin
```bash
mv trino ~/bin
```

export to path
```bash
echo 'export PATH=~/bin:$PATH' >> ~/.bashrc
```
activate the changes
```bash
source ~/.bashrc
```
## TROUBLE SHOOTING TRINO CLI CONNECTION WITH KERBEROS

when running newer version of trino (461) it latches on to kerberos on the installed system. Workaround was to unset kerberos which is done on ktpv-orch like this

Check the krb
```bash
env | grep -i krb
```
if there is some return, then run this command to unset kerberos

```bash
unset KRB5_CONFIG
unset KRB5CCNAME
```

Perhaps krb could be used to run the trino cli in worker01 with something like this
```bash
./trino \
  --server https://<trino-server-address> \
  --krb5-config-path /etc/krb5.conf \
  --krb5-principal <your-kerberos-principal> \
  --krb5-keytab-path /path/to/your.keytab \
  --krb5-remote-service-name trino
```
