# Installation and configuration of Harbor

## Prerequisites
Docker Engine	Version 20.10.10-ce+ or higher	
Docker compose v2
OpenSSL - 	Latest is preferred
tar

This is optional, but you can create a harbor user with permissions to docker and to execute the ./install.sh file:
```bash
sudo useradd -m -s /bin/bash harbor
```

Add a strong passwd and store in Pleasant
```bash
sudo passwd harbor
```

Add harbor user to docker
```bash
sudo usermod -aG docker harbor
```

Set permissions for home folder
```bash
sudo chown -R harbor:harbor /home/harbor
```

Switch to the harbor user
```bash
sudo su harbor
```

Then run 
```bash
chmod 750 /home/harbor
exit
```

Make the harbor/install.sh executable for the harbor user via sudo, open visudo
```bash
sudo visudo
```

and insert
```bash
harbor ALL=(ALL) NOPASSWD: /home/harbor/harbor/install.sh
```

## Download Harbor Installer
Go to the official download page `https://github.com/goharbor/harbor/releases`

download the offline installer*

```bash
wget https://github.com/goharbor/harbor/releases/download/v2.12.2/harbor-offline-installer-v2.12.2.tgz
```

untar the file
```Bash
tar xzvf harbor-offline-installer-v2.12.2.tgz
```

*of course download the newest version.

## Configure the Harbor YML file
Configure the `harbor.yml` file, according to the system and usage requirements. Details about the `harbor.yml` file can be found (here)[https://goharbor.io/docs/2.12.0/install-config/configure-yml-file/]

IMPORTANT, this server is set to run on port 3001 on server ktpv-orch

the parameter set will take effect when running `install.sh`

## Run the Installer Script
Once you have configured `harbor.yml` copied from `harbor.yml.tmpl` and optionally set up a storage backend, you install and start Harbor by using the `install.sh` script.

```
sudo ./install.sh
```

If the installation succeeds, you can open a browser to visit the Harbor interface at `http://reg.yourdomain.com`, changing `reg.yourdomain.com` to the hostname that you configured in `harbor.yml`. If you did not change them in `harbor.yml`, the default administrator username and password are `admin` and `Harbor12345`.

Log in to the admin portal and create a new project, for example, `myproject`. You can then use Docker commands to log in to Harbor, tag images, and push them to Harbor.

```
docker login reg.yourdomain.com
```

```
docker push reg.yourdomain.com/myproject/myrepo:mytag
```

If your installation of Harbor uses HTTP rather than HTTPS, you must add the option `--insecure-registry` to your client’s Docker daemon. By default, the daemon file is located at `/etc/docker/daemon.json`.

For example, add the following to your `daemon.json` file:
```
{
"insecure-registries" : ["myregistrydomain.com:5000", "0.0.0.0"]
}
```

After you update `daemon.json`, you must restart both Docker Engine and Harbor.

Restart Docker Engine.

```
systemctl restart docker
```

Stop Harbor.
```
docker compose down -v
```

Restart Harbor.
```
docker compose up -d
```

