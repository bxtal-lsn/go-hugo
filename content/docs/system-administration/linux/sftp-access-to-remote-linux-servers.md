# SFTP Access to Remote Linux Servers

## Introduction

Secure File Transfer Protocol (SFTP) is a robust, encrypted method for transferring files between systems. Unlike traditional FTP, SFTP operates over SSH, providing authentication and encryption for all operations. This guide covers both command-line and graphical SFTP access methods for remotely managing files on Linux servers.

SFTP is essential for:
- Secure file management on remote servers
- Automated deployments and configuration management
- Backup and restore operations
- Content publishing and website management
- System administration and troubleshooting

## Prerequisites

- [SSH access to remote Linux servers](#) already configured
- SSH key pair generated and properly set up
- Appropriate file system permissions on the remote server
- Network connectivity between client and server (port 22 open)

## Command-Line SFTP Access

### Basic Connection

The command-line SFTP client provides powerful, scriptable file transfer capabilities directly from your terminal.

```bash
# Basic syntax
sftp username@hostname_or_ip

# Example with specific user
sftp admin@192.168.1.100

# Example with domain username format
sftp user@domain.com@server-hostname

# Connect to a non-standard port
sftp -P 2222 username@hostname
```

### Authentication Methods

SFTP supports multiple authentication methods:

```bash
# Password authentication (prompted after command)
sftp username@hostname

# Explicit key-based authentication
sftp -i /path/to/private_key username@hostname

# Using SSH config for authentication
sftp server_alias  # Where server_alias is defined in ~/.ssh/config
```

### Basic SFTP Commands

Once connected, you'll be at the SFTP prompt. Common commands include:

| Command | Description | Example |
|---------|-------------|---------|
| `ls` | List directory contents | `ls /var/www` |
| `cd` | Change remote directory | `cd /opt/application` |
| `pwd` | Print working directory | `pwd` |
| `mkdir` | Create directory | `mkdir backups` |
| `rmdir` | Remove directory | `rmdir old_logs` |
| `get` | Download file | `get server.log` |
| `put` | Upload file | `put config.xml` |
| `mget` | Download multiple files | `mget *.log` |
| `mput` | Upload multiple files | `mput *.conf` |
| `rm` | Delete file | `rm obsolete.txt` |
| `chmod` | Change permissions | `chmod 644 index.html` |
| `exit` | Close connection | `exit` or `quit` |

### Local vs. Remote Commands

SFTP differentiates between local and remote commands:

```bash
# Local directory operations (prefix with 'l')
lpwd        # Show local working directory
lcd /tmp    # Change local directory
lls         # List local directory contents

# Remote operations (standard commands)
pwd         # Show remote working directory
cd /var/log # Change remote directory
ls          # List remote directory contents
```

### Batch Mode Operations

For non-interactive, scriptable transfers:

```bash
# Execute SFTP commands from a batch file
sftp -b commands.txt username@hostname

# Example contents of commands.txt:
# cd /var/www/html
# put index.html
# put styles.css
# put scripts.js
# exit
```

### Advanced Transfer Options

```bash
# Resume interrupted download
get -a large_file.iso

# Preserve timestamps during transfer
get -p document.pdf

# Set transfer limits (useful on production servers)
# Limit bandwidth to 1MB/s
sftp -l 1000000 username@hostname
```

## GUI SFTP Access with Cyberduck

Cyberduck is a feature-rich, open-source file transfer client available for Windows and macOS.

### Installation

1. Download Cyberduck:
   - Visit [cyberduck.io](https://cyberduck.io/)
   - Download the appropriate version for your operating system
   - Install following standard installation procedures

### Configuring Cyberduck for SFTP

1. **Launch Cyberduck** and click "Open Connection"

2. **Configure the connection:**
   - Select "SFTP (SSH File Transfer Protocol)" from the dropdown menu
   - Server: Enter the hostname or IP address of your server
   - Port: 22 (default SSH port)
   - Username: Your SSH username
   - Password: Leave blank if using SSH key authentication

3. **Configure SSH Key Authentication:**
   - Expand advanced options if necessary
   - For "SSH Private Key", navigate to your private key location
   - For WSL users, access your key at a path similar to:
     ```
     \\wsl.localhost\Distribution_Name\home\username\.ssh\id_rsa
     ```
     Example:
     ```
     \\wsl.localhost\OracleLinux_9_3\home\user\.ssh\id_rsa
     ```

4. **Save Bookmark (Optional):**
   - Click "Add to Keychain" or similar option to save connection details
   - Provide a descriptive name for this connection

5. **Connect** by clicking "Connect" button

### Using Cyberduck

Once connected:
- Navigate folders by double-clicking
- Upload files by dragging from your file explorer
- Download by dragging to your file explorer
- Right-click for additional options:
  - Edit permissions
  - Create new folders
  - Delete files/folders
  - Edit files directly (with external editor)
  - Synchronize directories

### Alternative GUI SFTP Clients

Other popular SFTP clients include:

1. **FileZilla**
   - Cross-platform (Windows, macOS, Linux)
   - Free and open-source
   - Supports multiple simultaneous transfers

2. **WinSCP** (Windows only)
   - Integrated text editor
   - Commander and Explorer interfaces
   - Batch scripting capabilities

3. **MobaXterm** (Windows)
   - All-in-one terminal tool with SFTP capabilities
   - Tabbed interface for multiple sessions
   - Built-in X server and terminal

## Configuring SFTP-Only Access

For enhanced security, you may want to restrict users to SFTP only (no shell access).

### Create SFTP-Only User

```bash
# Create a new user
sudo useradd -m sftp_user

# Set password
sudo passwd sftp_user

# Create upload directory
sudo mkdir -p /home/sftp_user/upload

# Set proper ownership
sudo chown sftp_user:sftp_user /home/sftp_user/upload

# Set directory permissions
sudo chmod 755 /home/sftp_user
sudo chmod 700 /home/sftp_user/upload
```

### Configure SSH Server for SFTP-Only Access

Edit SSH configuration:

```bash
sudo vi /etc/ssh/sshd_config
```

Add or modify these lines:

```
# At the bottom of the file, add:
Match User sftp_user
    ForceCommand internal-sftp
    PasswordAuthentication yes
    ChrootDirectory /home/sftp_user
    PermitTunnel no
    AllowAgentForwarding no
    AllowTcpForwarding no
    X11Forwarding no
```

Restart SSH service:

```bash
sudo systemctl restart sshd
```

### Directory Structure for Chrooted SFTP

When using `ChrootDirectory`, the directory ownership and permissions are critical:

```bash
# Root directory must be owned by root
sudo chown root:root /home/sftp_user

# User can only write to specific subdirectories
sudo mkdir -p /home/sftp_user/upload
sudo chown sftp_user:sftp_user /home/sftp_user/upload
```

## Troubleshooting SFTP Connections

### Common Issues and Solutions

#### Connection Refused

**Issue:** Unable to connect to SFTP server.

**Solutions:**
1. Verify SSH service is running:
   ```bash
   sudo systemctl status sshd
   ```

2. Check firewall settings:
   ```bash
   sudo firewall-cmd --list-all
   # Add SSH if needed
   sudo firewall-cmd --permanent --add-service=ssh
   sudo firewall-cmd --reload
   ```

3. Verify SSH is listening on expected port:
   ```bash
   sudo ss -tulpn | grep ssh
   ```

#### Permission Denied

**Issue:** Authentication failure or unable to access files.

**Solutions:**
1. Check username and password:
   ```bash
   # Test SSH connection first
   ssh username@hostname
   ```

2. Verify SSH key permissions:
   ```bash
   # Private key should be 600
   chmod 600 ~/.ssh/id_rsa
   # Public key should be 644
   chmod 644 ~/.ssh/id_rsa.pub
   ```

3. Check if authorized_keys contains your public key:
   ```bash
   cat ~/.ssh/authorized_keys
   ```

4. Verify file permissions on server:
   ```bash
   ls -la /path/to/directory
   # Ensure you have appropriate read/write permissions
   ```

#### Chroot Issues

**Issue:** "Write failed: broken pipe" with chrooted SFTP.

**Solution:**
```bash
# Check ownership of chroot directory
ls -la /home/sftp_user

# Ensure root ownership for chroot directory
sudo chown root:root /home/sftp_user
sudo chmod 755 /home/sftp_user

# Ensure proper logs for debugging
sudo grep "internal-sftp" /var/log/auth.log
```

### Debug Mode

For detailed connection troubleshooting:

```bash
# Verbose SFTP for debugging (add more v's for higher verbosity)
sftp -v username@hostname

# Super verbose output
sftp -vvv username@hostname
```

## Automating SFTP Transfers

### Using Shell Scripts

Create automated SFTP transfers with shell scripts:

```bash
#!/bin/bash
# File: sftp_backup.sh

# Define variables
SERVER="server.example.com"
USER="backup_user"
KEY_PATH="/home/user/.ssh/backup_key"
REMOTE_PATH="/var/backups"
LOCAL_PATH="/backups"
DATE=$(date +%Y%m%d)

# Create batch commands file
cat > /tmp/sftp_commands.txt << EOF
cd ${REMOTE_PATH}
get daily_backup_${DATE}.tar.gz ${LOCAL_PATH}/
exit
EOF

# Execute SFTP with batch commands
sftp -i ${KEY_PATH} -b /tmp/sftp_commands.txt ${USER}@${SERVER}

# Clean up
rm /tmp/sftp_commands.txt
```

Make script executable:
```bash
chmod +x sftp_backup.sh
```

### Using Expect Scripts

For more complex scenarios requiring interaction:

```bash
#!/usr/bin/expect
# File: automated_sftp.exp

set timeout 30
set server [lindex $argv 0]
set username [lindex $argv 1]
set password [lindex $argv 2]

spawn sftp $username@$server

expect "password:"
send "$password\r"

expect "sftp>"
send "cd /var/www/html\r"

expect "sftp>"
send "put index.html\r"

expect "sftp>"
send "exit\r"

expect eof
```

### Scheduling with Cron

Schedule regular SFTP transfers:

```bash
# Edit crontab
crontab -e

# Add scheduled transfer (daily at 2AM)
0 2 * * * /path/to/sftp_backup.sh

# For logging output
0 2 * * * /path/to/sftp_backup.sh > /var/log/sftp_backup.log 2>&1
```

## Best Practices for SFTP

### Security Recommendations

1. **Always use key-based authentication:**
   ```bash
   # Generate strong keys (RSA 4096 or Ed25519)
   ssh-keygen -t ed25519 -f ~/.ssh/sftp_key
   ```

2. **Restrict SFTP users to specific directories using chroot**

3. **Disable password authentication** when possible:
   ```
   # In /etc/ssh/sshd_config
   PasswordAuthentication no
   ```

4. **Use non-standard ports** to reduce automated attacks:
   ```
   # In /etc/ssh/sshd_config
   Port 2222
   ```

5. **Implement IP restrictions** for critical servers:
   ```
   # In /etc/ssh/sshd_config
   Match User sftp_user
       AllowUsers sftp_user@192.168.1.*
   ```

6. **Regularly audit SFTP access logs:**
   ```bash
   sudo grep sftp /var/log/auth.log
   ```

### Performance Optimization

1. **Compression for slow connections:**
   ```bash
   # Enable compression
   sftp -C username@hostname
   ```

2. **Multiple parallel transfers** for large operations:
   - In Cyberduck: Preferences → Transfers → "Transfer Files"
   - In FileZilla: Settings → Transfers → "Maximum simultaneous transfers"

3. **Buffer size optimization** for large file transfers:
   ```bash
   # Set buffer size to 32MB
   sftp -B 32768 username@hostname
   ```

## Enterprise SFTP Solutions

For enterprise environments with high-volume requirements:

1. **Dedicated SFTP servers:**
   - ProFTPD with mod_sftp
   - OpenSSH with custom configurations
   - Commercial solutions like GoAnywhere MFT or Cerberus FTP

2. **Load Balancing:**
   ```
   # HAProxy configuration example for SFTP load balancing
   listen sftp
       bind *:2222
       mode tcp
       balance roundrobin
       server sftp1 10.0.0.1:22 check
       server sftp2 10.0.0.2:22 check
   ```

3. **Monitoring and Alerting:**
   - Integrate with monitoring systems using log parsing
   - Create alerts for failed transfers or exceeded thresholds

## Conclusion

SFTP provides a secure, reliable method for file transfers to Linux servers. Whether you prefer command-line efficiency or graphical interfaces, properly configured SFTP access enables efficient remote file management while maintaining robust security. By following this guide, you can establish secure file transfer capabilities for administrative tasks, deployments, and automated operations.

---

## Additional Resources

- [OpenSSH Documentation](https://www.openssh.com/manual.html)
- [Cyberduck Documentation](https://docs.cyberduck.io/)
- [Linux SFTP Server Setup](https://www.digitalocean.com/community/tutorials/how-to-use-sftp-to-securely-transfer-files-with-a-remote-server)
- [SFTP Command Reference](https://man.openbsd.org/sftp)
