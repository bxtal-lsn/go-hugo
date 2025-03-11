# Disabling Shell History on Production Linux Servers

## Introduction

Command history in Linux shells provides convenience for users by allowing them to recall and reuse previous commands. However, in production environments, especially those with stringent security or compliance requirements, shell history can pose security risks by potentially exposing sensitive information such as passwords, encryption keys, or confidential operations.

This guide provides comprehensive instructions for disabling shell history on Oracle Linux and Ubuntu production servers, helping you:

- Prevent sensitive commands from being recorded
- Reduce security risks in high-security environments
- Comply with certain regulatory requirements
- Implement consistent history policies across server fleets

## Understanding Shell History

### How Shell History Works

In Bash (the default shell for most Linux distributions), command history is:

1. Stored in memory during an active session
2. Written to a history file (typically `~/.bash_history`) when the session ends
3. Controlled by several environment variables and settings

### Key History Configuration Variables

| Variable | Purpose | Default |
|----------|---------|---------|
| `HISTFILE` | Location of history file | `~/.bash_history` |
| `HISTSIZE` | Number of commands stored in memory | 1000 |
| `HISTFILESIZE` | Number of commands stored in history file | 2000 |
| `HISTCONTROL` | Controls how commands are stored | varies by distribution |
| `HISTIGNORE` | Patterns of commands to ignore | none by default |

### History Storage Locations

- **User-specific history**: `~/.bash_history`
- **System-wide configuration**: 
  - `/etc/profile`
  - `/etc/bash.bashrc` (Ubuntu)
  - `/etc/bashrc` (Oracle Linux/RHEL)

## Methods for Disabling Shell History

There are multiple approaches to disabling shell history, each with different scopes and persistence:

### 1. System-Wide Disabling (Affects All Users)

This approach disables history for all users on the system.

### 2. User-Specific Disabling (Affects Individual Users)

This approach targets specific users, such as administrative or service accounts.

### 3. Session-Specific Disabling (Temporary)

This approach disables history for the current session only.

## Implementation: Disabling Shell History System-Wide

### For Oracle Linux

```bash
# Edit the system-wide Bash configuration
sudo vi /etc/bashrc
```

Add the following lines at the end of the file:

```bash
# Disable command history
unset HISTFILE
HISTSIZE=0
HISTFILESIZE=0
set +o history
```

Save and close the file.

Alternatively, create a dedicated configuration file:

```bash
# Create a dedicated configuration file
sudo vi /etc/profile.d/disable_history.sh
```

Add the following content:

```bash
#!/bin/bash
# Disable command history system-wide
unset HISTFILE
HISTSIZE=0
HISTFILESIZE=0
set +o history
```

Save the file and make it executable:

```bash
sudo chmod +x /etc/profile.d/disable_history.sh
```

### For Ubuntu

```bash
# Edit the system-wide Bash configuration
sudo vi /etc/bash.bashrc
```

Add the following lines at the end of the file:

```bash
# Disable command history
unset HISTFILE
HISTSIZE=0
HISTFILESIZE=0
set +o history
```

Save and close the file.

Alternatively, use the profile.d approach:

```bash
# Create a dedicated configuration file
sudo vi /etc/profile.d/disable_history.sh
```

Add the following content:

```bash
#!/bin/bash
# Disable command history system-wide
unset HISTFILE
HISTSIZE=0
HISTFILESIZE=0
set +o history
```

Save the file and make it executable:

```bash
sudo chmod +x /etc/profile.d/disable_history.sh
```

## Implementation: Disabling History for Specific Users

### Modify User's Bash Profile

```bash
# Edit the user's bash profile
sudo vi /home/username/.bashrc
```

Add the following lines at the end:

```bash
# Disable command history
unset HISTFILE
HISTSIZE=0
HISTFILESIZE=0
set +o history
```

Save and close the file.

For root user:

```bash
sudo vi /root/.bashrc
```

Add the same lines as above.

### Using User-Specific Profile Files

```bash
# Create or edit the user's bash_profile
sudo vi /home/username/.bash_profile
```

Add the following:

```bash
# Disable command history
unset HISTFILE
HISTSIZE=0
HISTFILESIZE=0
set +o history
```

## Implementation: Session-Specific History Disabling

To disable history for a single session:

```bash
# Run these commands at the start of your session
unset HISTFILE
HISTSIZE=0
HISTFILESIZE=0
set +o history
```

To create a convenient alias for starting a "private" session:

```bash
# Add to your ~/.bashrc
alias private='unset HISTFILE; HISTSIZE=0; HISTFILESIZE=0; set +o history; echo "History recording disabled for this session."'
```

## Verification and Testing

After implementing any of the methods above, you should verify that history is properly disabled:

### Testing System-Wide Configuration

1. Log out and log back in as any user
2. Run some test commands
3. Verify history is not being recorded:

```bash
# This should show no command history
history

# This should confirm HISTSIZE is 0
echo $HISTSIZE

# This should return empty if HISTFILE is unset
echo $HISTFILE

# Check if history is being recorded
set -o | grep history
# Should show: history off
```

### Testing File-Based History

```bash
# Run some commands
ls -la
echo "test command"

# Check if history file exists or has been updated
ls -la ~/.bash_history
# Or
cat ~/.bash_history
```

## Advanced Configuration Options

### Selective History Control

Instead of completely disabling history, you can use more selective approaches:

#### Ignore Specific Commands

```bash
# Add to bashrc
HISTCONTROL=ignorespace:ignoredups
HISTIGNORE="ls*:ps*:history*:clear*"
```

This will:
- Ignore commands that start with a space (if you prepend a space before sensitive commands)
- Ignore duplicate commands
- Ignore commands that match the patterns specified in HISTIGNORE

#### Session-Based Control

Create a toggle function for enabling/disabling history:

```bash
# Add to bashrc
function histoff {
    unset HISTFILE
    set +o history
    echo "History recording disabled"
}

function histon {
    HISTFILE=~/.bash_history
    set -o history
    echo "History recording enabled"
}
```

### Alternatives to Disabling History

If complete history disabling is not ideal, consider these alternatives:

#### Command Logging with Enhanced Security

```bash
# Add to system-wide profile
HISTCONTROL=ignorespace:erasedups
HISTTIMEFORMAT="%F %T "
readonly HISTFILE
readonly HISTSIZE
readonly HISTFILESIZE
```

#### Implement Centralized Logging

For auditing without local history files:

```bash
# Add to bashrc or system-wide profile
function audit() {
    local cmd=$(history 1 | sed 's/^[ ]*[0-9]\+[ ]*//')
    logger -p local1.notice -t "$USER[$$]" "$cmd"
}
PROMPT_COMMAND="audit"
```

This logs commands to syslog instead of history files.

## Security Considerations

### Potential Issues with Disabling History

- **Audit trail**: Disabling history removes a valuable audit trail for troubleshooting and security analysis
- **Usability impact**: Users lose the ability to recall previous commands, which may reduce productivity
- **Incomplete security**: Simply disabling history doesn't protect against all command logging mechanisms

### Complementary Security Measures

1. **Session logging**: Consider implementing `script` or terminal session recording
2. **Centralized logging**: Set up remote syslog or auditd to capture command execution
3. **Access controls**: Implement stronger authentication and authorization controls
4. **Privileged access management**: Use solutions that provide controlled access with auditing
5. **Regular user training**: Educate users on handling sensitive information

## Best Practices for Production Environments

### Documentation

Always document history configuration changes:

```bash
# Add comments to configuration files
# SECURITY: History disabled as per security policy SEC-123
# Implementation date: YYYY-MM-DD
# Implemented by: Your Name
# Approved by: Security Team
unset HISTFILE
HISTSIZE=0
HISTFILESIZE=0
set +o history
```

### Configuration Management

For environments managed with configuration management tools:

#### Ansible Example

```yaml
# Task to disable shell history
- name: Disable shell history system-wide
  blockinfile:
    path: /etc/bash.bashrc
    block: |
      # SECURITY: History disabled as per security policy
      unset HISTFILE
      HISTSIZE=0
      HISTFILESIZE=0
      set +o history
    marker: "# {mark} ANSIBLE MANAGED BLOCK - HISTORY CONTROL"
```

#### Puppet Example

```puppet
file_line { 'disable_history_unset':
  ensure => present,
  path   => '/etc/bash.bashrc',
  line   => 'unset HISTFILE',
}

file_line { 'disable_history_size':
  ensure => present,
  path   => '/etc/bash.bashrc',
  line   => 'HISTSIZE=0',
}

file_line { 'disable_history_filesize':
  ensure => present,
  path   => '/etc/bash.bashrc',
  line   => 'HISTFILESIZE=0',
}

file_line { 'disable_history_set':
  ensure => present,
  path   => '/etc/bash.bashrc',
  line   => 'set +o history',
}
```

### Monitoring Configuration Drift

Regularly verify that history settings remain applied:

```bash
# Script to check history configuration
for user in $(getent passwd | cut -d: -f1,6 | grep -v "nologin\|false" | cut -d: -f1); do
  echo "Checking $user"
  sudo -u $user bash -c 'echo "HISTFILE: $HISTFILE, HISTSIZE: $HISTSIZE, HISTFILESIZE: $HISTFILESIZE"'
done
```

## Troubleshooting

### Common Issues

1. **History still being recorded**: 
   - Check for other profile files that might be re-enabling history
   - Verify precedence of configuration files

2. **Changes not taking effect**: 
   - Ensure users log out and log back in
   - Check if `.bash_profile` or other files override your settings

3. **Some shells still recording history**:
   - Remember that settings are shell-specific (bash, zsh, etc.)
   - Apply similar settings to all shell configurations used in your environment

### Diagnostic Commands

```bash
# Check current history settings
set -o | grep history
echo $HISTFILE
echo $HISTSIZE
echo $HISTFILESIZE

# Check profile loading sequence
bash -xl

# Check for history files
find /home -name ".bash_history" -type f -not -size 0
```

## Conclusion

Disabling shell history on production Linux servers is a straightforward process, but should be implemented as part of a comprehensive security strategy. By following this guide, you can effectively disable command history on Oracle Linux and Ubuntu servers while maintaining proper documentation and implementing complementary security measures.

Remember that while disabling history can help protect sensitive information, it should be balanced with auditing requirements and operational needs. Consider using centralized logging or other auditing mechanisms to maintain visibility into system operations while protecting sensitive command-line information.

---

## Additional Resources

- [Bash Manual - History Control](https://www.gnu.org/software/bash/manual/html_node/Bash-History-Facilities.html)
- [Linux Security Best Practices](https://www.cyberciti.biz/tips/linux-security.html)
- [CIS Benchmarks for Linux](https://www.cisecurity.org/benchmark/distribution_independent_linux)
- [NIST Security Guidelines](https://csrc.nist.gov/publications/sp800)
