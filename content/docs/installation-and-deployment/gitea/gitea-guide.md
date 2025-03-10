# Gitea Guide
Gitea is a lightweight, self-hosted Git service written in Go.  
It provides a complete platform for collaborative development with features including repository management, issue tracking, pull requests, and CI/CD integration through webhooks.  
Gitea requires minimal resources (can run on a Raspberry Pi), offers a clean web UI similar to GitHub, and supports authentication via built-in accounts, OAuth, or LDAP.  
Installation is straightforward via binaries, Docker, or package managers.  
Gitea is highly customizable through configuration files, supports migrations from other Git platforms, and can be extended via webhooks and the API.  
It's ideal for teams seeking a private, efficient Git solution with lower overhead than GitLab.

## Install Gitea Backend
This supposes you use a postgresql database on the same server as your Gitea instance.
Also, if using sqlite3, skip this step

If postgresql 16 is not installed on the Oracle Linux server, run

```bash
sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
sudo dnf -qy module disable postgresql
sudo dnf install -y postgresql16-server
sudo /usr/pgsql-16/bin/postgresql-16-setup initdb
sudo systemctl enable postgresql-16
sudo systemctl start postgresql-16
```

Switch to postgres superuser
```bash
sudo su -c "psql" - postgres
```

create gitea user. please use string password here

```sql
CREATE ROLE gitea WITH LOGIN PASSWORD 'gitea';
```

and then
```sql
CREATE DATABASE giteadb WITH OWNER gitea TEMPLATE template0 ENCODING UTF8 LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8';
```

####### if en_US not available ######
####### Start ######

create datababse with utf8. Perhaps the en_US is not installed on the server. Perhaps do this first

```bash
locale -a
```
```bash
sudo dnf install glibc-langpack-en
```
```bash
sudo localedef -i en_US -f UTF-8 en_US.UTF-8
```
```bash
sudo vim /etc/locale.conf
```

Add or modify the following line:
```bash
LANG=en_US.UTF-8
```
```bash
source /etc/locale.conf
```
```bash
locale
```

####### End ##### 


Allow the database user to access the database created above by adding the following authentication rule to `pg_hba.conf`.
`pg_hba.conf` is typicall located at `/var/lib/pgsql/16` or `/var/lib/postgresql/16/` 

For local database:
```conf
local    giteadb    gitea    scram-sha-256
```

[!NOTE]
Rules on pg_hba.conf are evaluated sequentially, that is the first matching rule will be used for authentication. Your PostgreSQL installation may come with generic authentication rules that match all users and databases. You may need to place the rules presented here above such generic rules if it is the case.

restart service
```bash
sudo systemctl restart postgresql-16
```

On your Gitea server, test connection to the database.
```sql
psql -U gitea -d giteadb
```

## Install Gitea on Oracle Linux

Download the binary to a amd64 linux system

```bash
wget -O gitea https://dl.gitea.com/gitea/1.23.1/gitea-1.23.1-linux-amd64
chmod +x gitea
```

For the next steps, git needs to be installed
```bash
git --version
```

If git is not installed on dnf use
```bash
sudo dnf install git-all
```

Create git user
```bash
# On Fedora/RHEL/CentOS:
groupadd --system git
adduser \
   --system \
   --shell /bin/bash \
   --comment 'Git Version Control' \
   --gid git \
   --home-dir /home/git \
   --create-home \
   git
```

create required dir structure. It is unclear with which user this should be done, but i guess you need to `sudo su` and then run the command

```bash
mkdir -p /var/lib/gitea/{custom,data,log}
chown -R git:git /var/lib/gitea/
chmod -R 750 /var/lib/gitea/
mkdir /etc/gitea
chown root:git /etc/gitea
chmod 770 /etc/gitea
```

copy the gitea binary globally
```bash
cp gitea /usr/local/bin/gitea
```

this sets the git user to root permissions to write to app.ini file, this should be changed after the web ui installation.

```bash
chmod 750 /etc/gitea
chmod 640 /etc/gitea/app.ini
```

## Run Gitea on Linux as a Service

copy this snippet into
```bash
sudo vim /etc/systemd/system/gitea.service
```

```conf
[Unit]
Description=Gitea (Git with a cup of tea)
After=network.target
###
# Don't forget to add the database service dependencies
###
#
#Wants=mysql.service
#After=mysql.service
#
#Wants=mariadb.service
#After=mariadb.service
#
#Wants=postgresql.service
#After=postgresql.service
#
#Wants=memcached.service
#After=memcached.service
#
#Wants=redis.service
#After=redis.service
#
###
# If using socket activation for main http/s
###
#
#After=gitea.main.socket
#Requires=gitea.main.socket
#
###
# (You can also provide gitea an http fallback and/or ssh socket too)
#
# An example of /etc/systemd/system/gitea.main.socket
###
##
## [Unit]
## Description=Gitea Web Socket
## PartOf=gitea.service
##
## [Socket]
## Service=gitea.service
## ListenStream=<some_port>
## NoDelay=true
##
## [Install]
## WantedBy=sockets.target
##
###

[Service]
# Uncomment the next line if you have repos with lots of files and get a HTTP 500 error because of that
# LimitNOFILE=524288:524288
RestartSec=2s
Type=simple
User=git
Group=git
WorkingDirectory=/var/lib/gitea/
# If using Unix socket: tells systemd to create the /run/gitea folder, which will contain the gitea.sock file
# (manually creating /run/gitea doesn't work, because it would not persist across reboots)
#RuntimeDirectory=gitea
ExecStart=/usr/local/bin/gitea web --config /etc/gitea/app.ini
Restart=always
Environment=USER=git HOME=/home/git GITEA_WORK_DIR=/var/lib/gitea
# If you install Git to directory prefix other than default PATH (which happens
# for example if you install other versions of Git side-to-side with
# distribution version), uncomment below line and add that prefix to PATH
# Don't forget to place git-lfs binary on the PATH below if you want to enable
# Git LFS support
#Environment=PATH=/path/to/git/bin:/bin:/sbin:/usr/bin:/usr/sbin
# If you want to bind Gitea to a port below 1024, uncomment
# the two values below, or use socket activation to pass Gitea its ports as above
###
#CapabilityBoundingSet=CAP_NET_BIND_SERVICE
#AmbientCapabilities=CAP_NET_BIND_SERVICE
###
# In some cases, when using CapabilityBoundingSet and AmbientCapabilities option, you may want to
# set the following value to false to allow capabilities to be applied on gitea process. The following
# value if set to true sandboxes gitea service and prevent any processes from running with privileges
# in the host user namespace.
###
#PrivateUsers=false
###

[Install]
WantedBy=multi-user.target
```

enable and start the service
```bash
sudo systemctl enable gitea --now
```


## Remove a Gitea and postgresql-16 Instance

1. Stop and Disable Services

```bash
sudo systemctl stop gitea
sudo systemctl disable gitea
sudo systemctl stop postgresql-16
sudo systemctl disable postgresql-16
```

Delete all files and directories related to Gitea:
```bash
sudo rm -rf /usr/local/bin/gitea
sudo rm -rf /var/lib/gitea
sudo rm -rf /etc/gitea
sudo rm -rf /home/git
sudo rm -f /etc/systemd/system/gitea.service
```

```bash
sudo userdel -r git
sudo groupdel git
sudo rm -rf /home/git
getent passwd git
getent group git
```
Remove PostgreSQL
```bash
sudo dnf remove -y postgresql16-server
sudo rm -rf /var/lib/pgsql/16
sudo rm -rf /var/lib/postgresql/16
sudo rm -rf /etc/postgresql
sudo rm -rf /usr/pgsql-16
sudo rm -f /etc/systemd/system/postgresql-16.service
```
Remove postgres repo
```bash
sudo dnf remove -y pgdg-redhat-repo
```
Log in to PostgreSQL as the postgres user and drop the Gitea database and user:

```bash
sudo su - postgres
psql
DROP DATABASE IF EXISTS giteadb;
DROP ROLE IF EXISTS gitea;
\q
exit
```
Remove Git (Optional)

```bash
sudo dnf remove -y git-all
```
Reload Systemd Daemon

```bash
sudo systemctl daemon-reload
```
Verify Removal
```bash
systemctl status gitea
```
Check that PostgreSQL is no longer running:
```bash
systemctl status postgresql-16
```


## Linux history example


sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm  
sudo dnf -qy module disable postgresql  
sudo dnf install -y postgresql16-server  
sudo /usr/pgsql-16/bin/postgresql-16-setup initdb  
sudo systemctl enable postgresql-16  
sudo systemctl start postgresql-16  
sudo su -c "psql" - postgres  
sudo su  
sudo systemctl restart postgresql-16  
psql -U gitea -d giteadb  
cd  
mkdir downloads  
cd downloads/  
wget -O gitea https://dl.gitea.com/gitea/1.23.1/gitea-1.23.1-linux-amd64  
chmod +x gitea  
sudo dnf install git-all  
sudo su  
cp gitea /usr/local/bin/gitea  
vi /etc/systemd/system/gitea.service  
systemctl enable gitea --now  
sudo systemctl status gitea  
sudo  
sudo su  
sudo su git  
sudo systemctl restart gitea  
sudo systemctl status gitea  
sudo systemctl start gitea  
sudo systemctl status gitea  
sudo systemctl restart gitea  
sudo systemctl status gitea  


