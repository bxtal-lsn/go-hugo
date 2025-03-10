# Install
sudo dnf remove -y docker docker-client docker-client-latest docker-common 
sudo dnf remove -y docker-latest docker-latest-logrotate docker-logrotate 
sudo dnf remove -y docker-engine


sudo dnf install -y yum-utils

yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.rep

sudo dnf install -y --nobest docker-ce docker-ce-cli containerd.io

sudo systemctl enable --now docker

sudo usermod -aG docker your_username

# Uninstall

```bash
sudo dnf remove docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
```  

```bash
sudo rm -rf /var/lib/docker
```

```bash
sudo rm -rf /var/lib/containerd
```
