# Mounting Windows Shares on Linux Servers

## Introduction

In mixed-environment infrastructures, accessing Windows file shares from Linux systems is a common requirement. This guide provides a detailed approach to mounting Windows SMB/CIFS shares on Linux servers, with a focus on secure credential management and automatic mounting for high availability.

When properly configured, this integration enables seamless file access across platforms, facilitating:
- Centralized file storage and backups
- Cross-platform application data sharing
- Legacy system integration
- Hybrid cloud environments

## Prerequisites

- Linux server (RHEL/CentOS/Fedora based distribution)
- Windows server or workstation with shared folders
- Network connectivity between systems
- Administrative access on both systems
- The Windows share must be accessible from the Linux server (firewall rules, etc.)

## Key Components

| Component | Purpose |
|-----------|---------|
| `cifs-utils` | Linux package providing tools for mounting CIFS/SMB filesystems |
| `/etc/fstab` | File system table controlling automatic mounts |
| `/mnt` directory | Standard Linux mount point for temporary filesystems |
| `.mntcredentials` | Secure credential storage file |
| `systemctl` | System control interface for managing services |
| `remote-fs.target` | Systemd target for remote filesystem mounts |

## Step-by-Step Implementation

### 1. Install Required CIFS Utilities

First, update your system and install the necessary CIFS utilities package:

```shell
# Update package repository
sudo dnf update -y

# Install CIFS utilities
sudo dnf install cifs-utils -y

# For Debian/Ubuntu-based systems, use:
# sudo apt update
# sudo apt install cifs-utils -y
```

### 2. Create Secure Credentials File

Store Windows authentication credentials securely:

```shell
# Create credentials file in root's home directory
sudo vim /root/.mntcredentials
```

Add the following content to the file:

```
username=<your_windows_username>
password=<your_windows_password>
domain=<windows_domain>  # Optional: Only needed for domain-joined shares
```

Secure the credentials file to prevent unauthorized access:

```shell
# Change permissions to restrict access to root only
sudo chmod 600 /root/.mntcredentials
```

> **Security Note**: The credentials file will contain plain text passwords. Ensure it's only readable by root and consider using more secure authentication methods like Kerberos for production environments.

### 3. Create the Mount Point

Create a directory where the Windows share will be mounted:

```shell
# Create mount directory
sudo mkdir -p /mnt/windows_share

# Optional: Set appropriate ownership and permissions
sudo chown root:root /mnt/windows_share
sudo chmod 755 /mnt/windows_share  # Readable by all, writable only by root
```

### 4. Configure Automatic Mounting in /etc/fstab

Edit the filesystem table to include the Windows share:

```shell
sudo vim /etc/fstab
```

Add the following line at the end of the file:

```shell
# Format: Windows_Share_Path Mount_Point FileSystem_Type Mount_Options Dump_Freq Pass_Num
\\\\<Windows_Server_IP>\\<Share_Name> /mnt/windows_share cifs credentials=/root/.mntcredentials,_netdev,defaults,uid=1000,gid=1000,file_mode=0755,dir_mode=0755 0 0
```

#### Example:

```shell
\\\\192.168.1.100\\shared_docs /mnt/windows_share cifs credentials=/root/.mntcredentials,_netdev,defaults 0 0
```

#### Mount Options Explained:

| Option | Description |
|--------|-------------|
| `credentials=` | Path to file containing authentication details |
| `_netdev` | Indicates this is a network device, delaying mount until network is available |
| `defaults` | Uses default mount options |
| `uid=1000,gid=1000` | Optional: Sets ownership of mounted files (change to match your user) |
| `file_mode=0755` | Optional: Sets permissions for files |
| `dir_mode=0755` | Optional: Sets permissions for directories |
| `vers=3.0` | Optional: Specifies SMB protocol version (2.0, 3.0, etc.) |
| `iocharset=utf8` | Optional: Character set for I/O operations |
| `noperm` | Optional: Disables permission checking (use with caution) |

### 5. Reload Systemd Daemon

After modifying system configuration files, reload the systemd daemon:

```shell
# Correct command is daemon-reload (not daemon-restart)
sudo systemctl daemon-reload
```

### 6. Enable and Start Remote Filesystem Target

Configure systemd to automatically mount remote filesystems at boot:

```shell
# Enable remote filesystem target
sudo systemctl enable remote-fs.target

# Start it immediately
sudo systemctl start remote-fs.target
```

### 7. Test the Mount

Verify the mount is working properly:

```shell
# Try mounting immediately without rebooting
sudo mount -a

# Verify mount is active
df -h | grep windows_share
mount | grep windows_share

# Test file operations
touch /mnt/windows_share/test_file.txt
ls -la /mnt/windows_share/
```

### 8. Test Automatic Mounting After Reboot

Reboot your system to ensure the share mounts automatically:

```shell
sudo reboot
```

After reboot, verify the mount is active:

```shell
df -h | grep windows_share
```

## Troubleshooting

### Common Issues and Solutions

#### Mount Fails After Network Interruption

If the mount fails after a network interruption:

```shell
# Unmount the share if in a failed state
sudo umount -f /mnt/windows_share

# Attempt to remount
sudo mount -a
```

#### Permission Denied Errors

If you encounter permission issues:

```shell
# Check the system logs
sudo journalctl -xe | grep mount
sudo journalctl -xe | grep cifs

# Verify credentials file permissions
ls -la /root/.mntcredentials

# Test with explicit username/password (for debugging only)
sudo mount -t cifs -o username=<user>,password=<pass> //Windows_Server/Share /mnt/windows_share
```

#### Network Connectivity Issues

If you suspect network problems:

```shell
# Test connectivity to Windows server
ping <Windows_Server_IP>

# Check if SMB port is accessible
telnet <Windows_Server_IP> 445

# Check firewall status
sudo firewall-cmd --list-all
```

#### SELinux Issues

On systems with SELinux enabled:

```shell
# Check if SELinux is blocking access
sudo ausearch -m avc --start recent

# Set appropriate context for mount point
sudo semanage fcontext -a -t cifs_t "/mnt/windows_share(/.*)?"
sudo restorecon -Rv /mnt/windows_share
```

## Advanced Configuration

### Mounting Multiple Shares

To mount multiple Windows shares, create separate mount points and fstab entries:

```shell
# Create additional mount points
sudo mkdir -p /mnt/windows_share2
sudo mkdir -p /mnt/windows_share3

# Add entries to fstab
\\\\192.168.1.100\\share1 /mnt/windows_share1 cifs credentials=/root/.mntcredentials,_netdev,defaults 0 0
\\\\192.168.1.100\\share2 /mnt/windows_share2 cifs credentials=/root/.mntcredentials,_netdev,defaults 0 0
```

### Using Different Credentials for Each Share

Create separate credentials files for different shares:

```shell
# Create credentials for specific shares
sudo vim /root/.share1_credentials
sudo vim /root/.share2_credentials

# Set permissions
sudo chmod 600 /root/.share*_credentials

# Reference in fstab
\\\\192.168.1.100\\share1 /mnt/windows_share1 cifs credentials=/root/.share1_credentials,_netdev,defaults 0 0
```

### Mounting with Kerberos Authentication (Domain Environments)

For more secure authentication in Active Directory environments:

```shell
# Install required packages
sudo dnf install krb5-workstation sssd-client -y

# Configure Kerberos
sudo vim /etc/krb5.conf

# Mount with Kerberos
\\\\server.domain.com\\share /mnt/windows_share cifs sec=krb5,_netdev,defaults 0 0
```

## Real-World Use Cases

### 1. Database Backups to Windows Storage

```shell
#!/bin/shell
# Script to backup PostgreSQL database to Windows share
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
pg_dump -U postgres mydatabase | gzip > /mnt/windows_share/backups/db_backup_${TIMESTAMP}.sql.gz
```

### 2. Log Aggregation from Windows Systems

```shell
# Create symbolic links from local log directory to Windows share
ln -s /mnt/windows_share/logs/iis_logs /var/log/remote/iis
ln -s /mnt/windows_share/logs/event_logs /var/log/remote/windows_events

# Configure log rotation for remote logs
sudo vim /etc/logrotate.d/remote-windows
```

### 3. Cross-Platform Development Environment

```shell
# Create project directories
mkdir -p /mnt/windows_share/projects/web-app

# Configure IDE to use shared project folder
code /mnt/windows_share/projects/web-app

# Configure version control to ignore OS-specific files
cat > /mnt/windows_share/projects/.gitignore << EOF
# Windows specific
Thumbs.db
desktop.ini
# Linux specific
.directory
.Trash-*
EOF
```

## Security Considerations

1. **Encrypted Transport**: For sensitive data, consider using encryption:
   ```shell
   # Add to mount options
   \\\\server\\share /mnt/windows_share cifs credentials=/root/.mntcredentials,seal,_netdev 0 0
   ```

2. **Credential Management**: Consider using a secrets management system like HashiCorp Vault instead of plaintext credential files.

3. **Mount Options Hardening**:
   ```shell
   # Add security-enhancing mount options
   \\\\server\\share /mnt/windows_share cifs credentials=/root/.mntcredentials,_netdev,noexec,nosuid,nodev 0 0
   ```

4. **Restrict Access**: Use appropriate permissions on the mount point to limit user access:
   ```shell
   sudo chown root:specific_group /mnt/windows_share
   sudo chmod 750 /mnt/windows_share
   ```

## Conclusion

Properly configured Windows share mounts on Linux systems provide seamless cross-platform file access while maintaining security and reliability. By following this guide, you can integrate Windows and Linux environments effectively, enabling centralized storage, simplified backups, and cross-platform workflows.

Remember to regularly test your mounts, especially after system updates, and keep your authentication credentials secure. For production environments, consider implementing more advanced authentication methods like Kerberos or certificate-based authentication for enhanced security.
