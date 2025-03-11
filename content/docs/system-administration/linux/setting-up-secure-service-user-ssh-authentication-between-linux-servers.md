# Setting Up Secure Service User SSH Authentication Between Linux Servers

## Introduction

In enterprise environments, automating secure communication between servers is critical for maintaining robust infrastructure. This guide will walk you through establishing passwordless SSH authentication between two Linux servers using a service user—ideal for automated tasks, CI/CD pipelines, backup processes, and container orchestration systems.

## Prerequisites

- Root or sudo access on both servers
- SSH service running on both servers
- Network connectivity between servers
- Basic understanding of Linux permissions and SSH concepts

## Architecture Overview

```
┌──────────── ─┐                 ┌─────────── ──┐
│             │                 │             │
│   Server A  │◄───SSH Conn.───►   Server B   │
│  (Source)   │                 │  (Target)   │
│             │                 │             │
└─────────── ──┘                 └──────────── ─┘
```

## 1. Create Service User (If Not Already Existing)

Both servers require the same service user. This step should be performed on both Server A and Server B if the user doesn't already exist.

```shell
# Create user with no password and a proper home directory
sudo useradd -m -s /bin/bash container_user

# If you need specific group membership (e.g., for Docker access)
sudo usermod -aG docker container_user

# Set proper permissions on the home directory
sudo chmod 750 /home/container_user
```

## 2. Generate SSH Key Pair (Server A)

On Server A (source server), generate a strong, modern key:

```shell
# Switch to the service user
sudo su - container_user

# Create SSH directory if it doesn't exist
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Generate Ed25519 key (more secure and efficient than RSA)
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

# For legacy systems that don't support Ed25519, use RSA with 4096 bits
# ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# Ensure proper permissions
chmod 600 ~/.ssh/id_ed25519
```

> **Security Note**: The `-N ""` parameter creates a key without a passphrase, which is necessary for automation but reduces security. For higher security environments, consider using `ssh-agent` or HashiCorp Vault for key management.

## 3. Copy Public Key to Server B

```shell
# On Server A: View and copy the public key
cat ~/.ssh/id_ed25519.pub
```

Then on Server B:

```shell
# Switch to the service user
sudo su - container_user

# Create .ssh directory with proper permissions
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Add the public key to authorized_keys
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI..." > ~/.ssh/authorized_keys

# Alternative: use an editor to paste the key
vim ~/.ssh/authorized_keys

# Set correct permissions
chmod 600 ~/.ssh/authorized_keys

# Fix SELinux context if applicable (RHEL/CentOS/Fedora)
sudo restorecon -Rv ~/.ssh
```

## 4. Test Connection (From Server A)

```shell
# As container_user on Server A
ssh -i ~/.ssh/id_ed25519 container_user@SERVER_B_IP

# For first-time connections, you'll be prompted to accept the host key
# To skip this in automated scripts, add:
ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 container_user@SERVER_B_IP
```

## 5. Enhanced Security Configuration (Server B)

Harden the SSH configuration on Server B:

```shell
# Edit the SSH daemon configuration
sudo vim /etc/ssh/sshd_config

# Make these changes:
PasswordAuthentication no
PermitRootLogin no
AllowUsers container_user [other_users]
```

Or use sed for automated changes:

```shell
# Disable password authentication
sudo sed -i 's/^#\?PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Disable root login
sudo sed -i 's/^#\?PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Restart/reload SSH service
sudo systemctl reload sshd
```

## 6. Creating Config File for Easy Access (Server A)

For convenience, create an SSH config file:

```shell
# As container_user on Server A
cat > ~/.ssh/config << EOF
Host serverb
    HostName SERVER_B_IP
    User container_user
    IdentityFile ~/.ssh/id_ed25519
    Port 22
EOF

chmod 600 ~/.ssh/config

# Now you can connect with just:
ssh serverb
```

## Real-World Use Cases

### 1. Automated Database Backups

```shell
# On Server A, create a backup script
cat > ~/backup_db.sh << 'EOF'
#!/bin/bash
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ssh serverb "pg_dump -U postgres mydb | gzip -9" > /backup/mydb_${TIMESTAMP}.sql.gz
EOF

chmod +x ~/backup_db.sh

# Set up a cron job
crontab -e
# Add: 0 2 * * * /home/container_user/backup_db.sh
```

### 2. Container Log Collection

```shell
# Collect Docker logs from Server B
ssh serverb "docker logs --tail=1000 my_container" | grep ERROR > /var/log/container_errors.log
```

### 3. High Availability Health Checks

Create a script that monitors services on Server B:

```shell
#!/bin/bash
# Check Kubernetes node status
NODE_STATUS=$(ssh serverb "kubectl get nodes | grep 'Ready'")
if [[ -z "$NODE_STATUS" ]]; then
    # Send alert via your monitoring system
    curl -X POST https://alerts.example.com/api/v1/alert -d '{"message":"Node down!"}'
fi
```

### 4. Ansible Integration

Instead of hardcoding SSH credentials, reference your SSH config in Ansible:

```yaml
# inventory.yml
all:
  hosts:
    serverb:
      ansible_user: container_user
      ansible_ssh_private_key_file: /home/container_user/.ssh/id_ed25519
```

## Troubleshooting

### Permission Issues

If you encounter "Permission denied" errors:

```shell
# Check SSH daemon logs
sudo journalctl -u sshd

# Verify file permissions
ls -la ~/.ssh/
sudo ls -la /home/container_user/.ssh/

# Ensure proper SELinux contexts
sudo restorecon -Rv ~/.ssh
```

### Key Authentication Failures

```shell
# Debug connection attempts
ssh -vvv -i ~/.ssh/id_ed25519 container_user@SERVER_B_IP

# Check authorized_keys format (should be one line per key)
cat ~/.ssh/authorized_keys
```

## Security Best Practices

1. **Rotate keys regularly** using cron jobs or configuration management tools
2. **Restrict user capabilities** with `sudoers` configurations for the service user
3. **Implement IP restrictions** in `/etc/ssh/sshd_config` with `AllowUsers` directives
4. **Monitor authentication attempts** with log analysis tools
5. **Consider jump hosts** for additional security layers in sensitive environments

By following this guide, you'll establish a secure, automated connection between servers that's suitable for production environments with critical applications, while maintaining high security standards.
