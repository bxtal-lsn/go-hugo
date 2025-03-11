# Linux Server Security Hardening

## Introduction

Server security is a critical aspect of infrastructure management that requires continuous attention and proactive measures. This guide focuses on hardening SSH access and implementing additional security layers on Linux servers to protect against unauthorized access, brute force attacks, and other common security threats.

Properly secured SSH configurations are your first line of defense for internet-facing servers. When combined with intrusion prevention tools like Fail2Ban, you create a robust security posture that dramatically reduces your attack surface.

## Prerequisites

- Administrative (sudo) access to the target Linux server
- Basic knowledge of Linux command line and text editors
- [SSH access to remote Linux servers already configured](#) (cross-reference to your existing documentation)

## SSH Security Hardening

SSH (Secure Shell) is the primary method for remote server administration. While it's secure by default, several additional configuration options can significantly enhance its security.

### Backup Your Configuration

Always create a backup before modifying critical configuration files:

```shell
# Navigate to the SSH configuration directory
cd /etc/ssh

# Create a backup of your current configuration
sudo cp sshd_config sshd_config.bak.$(date +%Y%m%d)
```

### Edit SSH Daemon Configuration

Open the SSH daemon configuration file:

```shell
sudo vi /etc/ssh/sshd_config
```

Alternatively, you can use any text editor you're comfortable with:

```shell
sudo nano /etc/ssh/sshd_config
# or
sudo vim /etc/ssh/sshd_config
```

### Key Security Settings

#### 1. Password Authentication

**Setting:** `PasswordAuthentication no`

**Security Implication:**
Disabling password authentication forces all users to authenticate using SSH keys, which are significantly more secure than passwords as they're resistant to brute force attacks. SSH keys use cryptographic pairs, with the private key remaining on the client and the public key on the server.

**Implementation:**
```vim
:/ PasswordAuth
```

Change from:
```
#PasswordAuthentication yes
```
To:
```
PasswordAuthentication no
```

> **Caution:** Before disabling password authentication, ensure:
> - At least one administrator account has working SSH key access
> - You've tested SSH key authentication as this account
> - You have an alternative method to access the server if needed

#### 2. Root Login Permissions

**Setting:** `PermitRootLogin no`

**Security Implication:**
Disabling direct root login via SSH prevents attackers from targeting the most privileged account on your system. This forces administrators to first login as a regular user and then escalate privileges using `sudo`, adding an extra security layer.

**Implementation:**
```vim
:/ Root
```

Change from:
```
#PermitRootLogin yes
```
To:
```
PermitRootLogin no
```

#### 3. Maximum Authentication Attempts

**Setting:** `MaxAuthTries 3`

**Security Implication:**
Limiting authentication attempts helps prevent brute force attacks by restricting the number of password guesses per connection. After the specified number of failures, the SSH daemon disconnects the client.

**Implementation:**
```vim
:/ MaxAuthT
```

Change from:
```
#MaxAuthTries 6
```
To:
```
MaxAuthTries 3
```

#### 4. Empty Password Prevention

**Setting:** `PermitEmptyPasswords no`

**Security Implication:**
This prevents users with empty passwords from logging in via SSH. This is a critical security measure as accounts without passwords are extremely vulnerable.

**Implementation:**
```vim
:/ PermitEmptyPassw
```

Ensure it's set to:
```
PermitEmptyPasswords no
```

#### 5. Disable Kerberos Authentication

**Setting:** `KerberosAuthentication no`

**Security Implication:**
Unless you're specifically using Kerberos for authentication, disabling this reduces the attack surface by removing an unused authentication method.

**Implementation:**
```vim
:/ KerberosAuth
```

Ensure it's set to:
```
KerberosAuthentication no
```

#### 6. Disable GSSAPI Authentication

**Setting:** `GSSAPIAuthentication no`

**Security Implication:**
Similar to Kerberos, disabling GSSAPI authentication when not needed reduces potential security vulnerabilities from unused features.

**Implementation:**
```vim
:/ GSSAPI
```

Change from:
```
GSSAPIAuthentication yes
```
To:
```
GSSAPIAuthentication no
```

### Apply SSH Configuration Changes

After making changes, restart the SSH daemon to apply them:

```shell
sudo systemctl restart sshd
```

> **Critical Warning:** Do not close your current SSH session until you've verified that you can establish a new SSH connection with the updated configuration. Keep at least one session open as a fallback.

## Implementing Fail2Ban

Fail2Ban is an intrusion prevention tool that monitors log files and takes action against suspicious activities, such as multiple failed login attempts.

### Installation

First, ensure your system is up-to-date and has the necessary repositories:

```shell
# Update system packages
sudo dnf update -y

# Install EPEL repository if not already available
sudo dnf install epel-release -y

# Install Fail2Ban
sudo dnf install fail2ban -y
```

> For Debian/Ubuntu-based systems, use:
> ```shell
> sudo apt update
> sudo apt install fail2ban -y
> ```

### Configuration

Start and enable Fail2Ban to run on system boot:

```shell
sudo systemctl enable --now fail2ban
```

Create a custom configuration file:

```shell
# Navigate to Fail2Ban configuration directory
cd /etc/fail2ban

# Create a custom jail configuration
sudo vi jail.local
```

Add the following basic configuration:

```
[DEFAULT]
# Ban hosts for one hour (3600 seconds):
bantime = 3600

# Ban IP after 3 failed login attempts
maxretry = 3

# Amount of time in seconds to look back for failures
findtime = 600

# Default action (adjusts firewall rules to ban the IP)
banaction = iptables-multiport

# Email notifications (optional)
# destemail = your-email@domain.com
# sendername = Fail2Ban
# mta = sendmail
# action = %(action_mwl)s

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
```

> **Note:** On RHEL/CentOS/Fedora systems, the SSH log path is typically `/var/log/secure` rather than `/var/log/auth.log`. Adjust accordingly:
> ```
> logpath = /var/log/secure
> ```

### Apply Fail2Ban Configuration

Restart Fail2Ban to apply the changes:

```shell
sudo systemctl restart fail2ban
```

### Verify Fail2Ban Status

Check that Fail2Ban is running properly:

```shell
# Check service status
sudo systemctl status fail2ban

# View active jails
sudo fail2ban-client status

# View detailed status for SSH jail
sudo fail2ban-client status sshd
```

## Additional Security Measures

Beyond SSH and Fail2Ban, consider these additional security practices:

### 1. Change Default SSH Port

Changing the default SSH port (22) can reduce automated scanning attempts:

```shell
# In /etc/ssh/sshd_config
Port 2222  # Choose a port between 1024 and 65535
```

> **Note:** Remember to update your firewall rules and connection commands after changing the port.

### 2. Limit User SSH Access

Restrict SSH access to specific users or groups:

```shell
# In /etc/ssh/sshd_config
AllowUsers user1 user2 admin
# Or
AllowGroups sshusers admins
```

### 3. Configure SSH Timeouts

Set timeouts to disconnect inactive sessions:

```shell
# In /etc/ssh/sshd_config
ClientAliveInterval 300
ClientAliveCountMax 2
```

This disconnects clients after 10 minutes of inactivity (300 seconds × 2 intervals).

### 4. Use Strong Ciphers and Key Exchange Algorithms

Strengthen SSH encryption:

```shell
# In /etc/ssh/sshd_config
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group-exchange-sha256
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256
```

### 5. Configure Firewall Rules

Implement firewall rules to further restrict access:

```shell
# Allow SSH on default port (or your custom port)
sudo firewall-cmd --permanent --add-service=ssh
# For custom port
sudo firewall-cmd --permanent --add-port=2222/tcp

# Reload firewall
sudo firewall-cmd --reload
```

### 6. Regular Updates

Keep your system updated with security patches:

```shell
# Create a cron job for automatic updates
echo "0 3 * * * root dnf -y update --security" | sudo tee /etc/cron.d/security-updates
```

## Monitoring and Verification

### Monitor Auth Logs

Regularly check authentication logs for suspicious activities:

```shell
# View recent authentication attempts
sudo tail -f /var/log/secure

# Search for failed login attempts
sudo grep "Failed password" /var/log/secure | tail -n 20
```

### Check Fail2Ban Logs

Monitor Fail2Ban's actions:

```shell
sudo tail -f /var/log/fail2ban.log
```

### Test Your Configuration

Test your SSH security from an external system:

```shell
# Attempt SSH connection with verbose output
ssh -v username@server_ip
```

## Troubleshooting

### SSH Access Issues

If you can't connect after making changes:

1. Access the server through an alternative method (console, VPN, etc.)
2. Check SSH service status: `sudo systemctl status sshd`
3. Review configuration errors: `sudo sshd -t`
4. Revert to the backup configuration if needed: `sudo cp /etc/ssh/sshd_config.bak.YYYYMMDD /etc/ssh/sshd_config`

### Fail2Ban Issues

If Fail2Ban isn't working as expected:

1. Check the status: `sudo fail2ban-client status`
2. Review logs: `sudo tail -f /var/log/fail2ban.log`
3. Verify jail configuration: `sudo fail2ban-client get sshd failregex`
4. Restart the service: `sudo systemctl restart fail2ban`

## Enterprise-Level Considerations

For larger environments, consider these advanced measures:

### 1. Centralized Authentication

Implement LDAP or Active Directory integration for centralized user management:

```shell
# Install necessary packages
sudo dnf install sssd sssd-ldap oddjob-mkhomedir -y

# Configure SSSD for LDAP authentication
sudo vi /etc/sssd/sssd.conf
```

### 2. Multi-Factor Authentication (MFA)

Add an extra layer of security with MFA for SSH:

```shell
# Install Google Authenticator PAM module
sudo dnf install google-authenticator -y

# Configure PAM
sudo vi /etc/pam.d/sshd
# Add: auth required pam_google_authenticator.so

# In /etc/ssh/sshd_config
ChallengeResponseAuthentication yes
```

### 3. Configuration Management

Use tools like Ansible, Puppet, or Chef to maintain consistent security configurations across servers:

```yaml
# Ansible example for SSH hardening
- name: Ensure SSH security settings
  template:
    src: templates/sshd_config.j2
    dest: /etc/ssh/sshd_config
    validate: '/usr/sbin/sshd -t -f %s'
  notify: Restart sshd
```

## Security Audit Checklist

Use this checklist to verify your server's SSH security hardening:

- [ ] Password authentication disabled or restricted
- [ ] Root login disabled
- [ ] Maximum authentication attempts limited
- [ ] Empty passwords not permitted
- [ ] Unused authentication methods disabled
- [ ] Fail2Ban properly configured and running
- [ ] SSH using strong ciphers and algorithms
- [ ] Regular security updates configured
- [ ] SSH access limited to necessary users
- [ ] Firewall properly configured
- [ ] Security logs monitored

## Conclusion

Implementing these security measures creates a robust defense against common attack vectors. Remember that security is not a one-time configuration but an ongoing process requiring regular reviews, updates, and monitoring.

By following this guide, you've significantly improved your Linux server's security posture, particularly against SSH-based attacks which are among the most common threats to internet-facing servers.

---

## Additional Resources

- [OpenSSH Security Best Practices](https://www.ssh.com/academy/ssh/security)
- [Fail2Ban Documentation](https://www.fail2ban.org/wiki/index.php/Main_Page)
- [Linux Server Security Guide](https://www.cyberciti.biz/tips/linux-security.html)
- [CIS Benchmarks for Linux](https://www.cisecurity.org/benchmark/distribution_independent_linux)
