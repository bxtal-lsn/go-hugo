# PostgreSQL Backup and Recovery Guide for Windows
> *Note: This guide was originally written for PostgreSQL 12. See the [PostgreSQL 16 Changes](#postgresql-16-changes) section for important updates.*

## Table of Contents
- [Logical Backups](#logical-backups)
- [Restoring Logical Backups](#restoring-logical-backups)
- [Physical Backups](#physical-backups)
- [Point-In-Time Recovery (PITR)](#point-in-time-recovery-pitr)
- [Setting Up WAL Archiving](#setting-up-wal-archiving)
- [Recovery Configuration](#recovery-configuration)
- [PITR Demo Example](#pitr-demo-example)
- [Backup Validation](#backup-validation)
- [Automation Options for Windows](#automation-options-for-windows)
- [PostgreSQL 16 Changes](#postgresql-16-changes)
- [Production-Ready Backup Plan (Compressed Version)](#production-ready-backup-plan-compressed-version)

## Logical Backups

Logical backups create a consistent copy of the database at execution time. These are recommended for databases under 100 GB.

### Using pg_dump and pg_dumpall

```shell
# Backup a single database
pg_dump -U postgres -d <database-name> > C:\path\to\backup.sql

# Backup all databases
pg_dumpall -U postgres > C:\path\to\backup.sql
```

These commands write data to plain text SQL files that can be used for database restoration.

### Compressed and Split Dumps

```shell
# Compressed backup (Windows with gzip installed)
pg_dump -U postgres -d <database-name> | gzip > C:\path\to\backup.sql.gz

# Split backup for large databases (Windows with split utility)
pg_dump -U postgres -d <database-name> | split -b 1G - C:\path\to\backup.sql.part_
```

### Custom Format Backups

```shell
# Create a custom format backup (compressed and supports parallel restore)
pg_dump -U postgres -Fc -d <database-name> > C:\path\to\database-name.dump
```

## Restoring Logical Backups

### Using the psql interface

To restore a database from a SQL file backup:

1. First create an empty database:
   ```sql
   CREATE DATABASE <database-name>;
   ```

2. Connect to the database:
   ```
   \c <database-name>
   ```

3. Verify it's empty:
   ```
   \d
   ```

4. Restore from backup:
   ```shell
   psql -U postgres -d <database-name> < C:\path\to\backup.sql
   ```

### Using pg_restore (for custom format backups)

Restore an entire database:
```shell
pg_restore -U postgres -d <database-name> C:\path\to\database-name.dump
```

Restore a specific table:
```shell
pg_restore -U postgres -t employee -d <database-name> C:\path\to\database-name.dump
```

## Physical Backups

Physical backups copy the database files directly, which is faster for large databases.

### Offline Backup (Development Only)

```shell
# Stop PostgreSQL
pg_ctl stop

# Verify it's stopped
pg_ctl status

# Create a tar archive of the data directory
tar -cvzf data_backup.tar.gz "C:\Program Files\PostgreSQL\12\data"

# Restart PostgreSQL when done
pg_ctl start
```

## Setting Up WAL Archiving

Continuous archiving enables Point-In-Time Recovery by copying Write-Ahead Log (WAL) files to another location.

1. Check the current archive mode:
   ```sql
   SHOW archive_mode;
   ```

2. Stop PostgreSQL:
   ```shell
   pg_ctl stop
   ```

3. Edit `postgresql.conf` in `C:\Program Files\PostgreSQL\12\data\`:
   ```
   # Change these parameters
   wal_level = replica
   archive_mode = on
   archive_command = 'copy "%p" "C:\\archivedir\\%f"'
   ```

4. Create the archive directory:
   ```shell
   mkdir C:\archivedir
   ```

5. Start PostgreSQL:
   ```shell
   pg_ctl start
   ```

6. Test WAL archiving:
   ```sql
   SELECT pg_switch_wal();
   ```

## Online Backup Methods

### Using pg_basebackup

The `pg_basebackup` utility takes a backup of an online PostgreSQL cluster. It can be used for PITR or replication.

```shell
# View help options
pg_basebackup --help

# Example with common options
pg_basebackup -U postgres -D "C:\path\to\backup\folder" -Ft -z -P -Xs
```

Options explained:
- `-Ft`: Format tar
- `-z`: Compress with gzip
- `-P`: Show progress
- `-Xs`: Include transaction logs (WAL) via streaming

### Using Low-Level API Backup

1. Start the backup:
   ```sql
   SELECT pg_start_backup('backup_label', false, false);
   ```

2. Copy the data directory:
   ```shell
   tar -cvzf backup.tar.gz "C:\Program Files\PostgreSQL\12\data"
   ```

3. Stop the backup:
   ```sql
   SELECT pg_stop_backup(false);
   ```

## Recovery Configuration

For Point-In-Time Recovery, you need to set up the recovery configuration.

Edit `postgresql.conf` to add:

```
# Command to retrieve archived WAL files
restore_command = 'copy "C:\\archivedir\\%f" "%p"'

# Recovery target options (use ONE of these)
recovery_target = 'immediate'                      # Recover to a consistent state
recovery_target_lsn = '<lsn-number>'               # Recover to a specific LSN
recovery_target_name = '<recovery-target-name>'    # Recover to a named point
recovery_target_time = '2022-08-06 12:52:00'      # Recover to a specific time
recovery_target_xid = '<transaction-id>'           # Recover to a specific transaction

# Whether to stop just after the target is reached
recovery_target_inclusive = true
```

To find the current LSN:
```sql
SELECT pg_current_wal_lsn(), pg_walfile_name(pg_current_wal_lsn());
```

## PITR Demo Example

This example demonstrates a complete PITR workflow.

### Setup

1. Ensure archive mode is on
2. Take a full backup:
   ```shell
   pg_basebackup -U postgres -Ft -D C:\backup
   ```

3. Create and populate a test table:
   ```sql
   CREATE TABLE root1(empno int, empname varchar(50), salary int);
   
   -- Insert data via SQL file
   \i insert_table1.sql
   
   -- Verify count
   SELECT count(*) FROM root1;
   
   -- Switch WAL to ensure data is archived
   SELECT pg_switch_wal();
   ```

### Simulating Data Loss

1. Delete data:
   ```sql
   DELETE FROM root1 WHERE empno > 50;
   
   -- Ensure the deletion is archived
   SELECT pg_switch_wal();
   ```

### Recovery Process

1. Stop PostgreSQL:
   ```shell
   pg_ctl stop
   ```

2. Restore the base backup:
   ```shell
   tar xvf C:\backup\base.tar -C "C:\Program Files\PostgreSQL\12\data"
   ```

3. Edit `postgresql.conf` to add:
   ```
   restore_command = 'copy "C:\\archivedir\\%f" "%p"'
   recovery_target_time = '2022-08-06 12:52:00'  # Time before the deletion
   ```

4. Create a recovery signal file:
   ```shell
   type nul > "C:\Program Files\PostgreSQL\12\data\recovery.signal"
   ```

5. Start PostgreSQL:
   ```shell
   pg_ctl start
   ```

6. Check logs in `data\logs` to monitor recovery progress

7. After recovery completes, switch to normal operation:
   ```sql
   SELECT pg_wal_replay_resume();
   ```

8. Verify the data is restored:
   ```sql
   SELECT count(*) FROM root1;
   ```

## Backup Validation

Regularly validating backups is essential to ensure they're usable when needed. Here are methods to validate different backup types:

### Logical Backup Validation

For SQL dumps:
```shell
# Check syntax without executing
psql -U postgres -f C:\path\to\backup.sql --command="" 2>&1 | findstr "ERROR"

# Create a test database and restore (more thorough)
CREATE DATABASE backup_test;
psql -U postgres -d backup_test < C:\path\to\backup.sql

# Verify object count matches production
psql -U postgres -d backup_test -c "SELECT count(*) FROM pg_class WHERE relkind='r' AND relnamespace > 16384;"
```

For custom format dumps:
```shell
# Verify dump file integrity
pg_restore -l C:\path\to\database-name.dump > dump_contents.txt

# Test restore to a temporary database
pg_restore -U postgres -d backup_test C:\path\to\database-name.dump
```

### Physical Backup Validation

For physical backups and WAL archives:
```shell
# Test the backup by restoring to a test server
# This requires a separate PostgreSQL installation

# Copy the backup to test server data directory
# Start the test server with recovery configuration
# Verify data integrity after recovery
```

## Automation Options for Windows

### Using Windows Task Scheduler

1. Create a backup script (e.g., `backup_postgres.bat`):
```batch
@echo off
set PGPASSWORD=yourpassword
set BACKUP_DIR=C:\PostgreSQL\backups
set LOG_DIR=C:\PostgreSQL\logs
set DB_NAME=your_database
set DATE_FORMAT=%date:~10,4%%date:~4,2%%date:~7,2%

rem Create directories if they don't exist
if not exist %BACKUP_DIR% mkdir %BACKUP_DIR%
if not exist %LOG_DIR% mkdir %LOG_DIR%

echo Starting backup at %time% >> %LOG_DIR%\backup_%DATE_FORMAT%.log

rem Logical backup (custom format)
pg_dump -U postgres -Fc -d %DB_NAME% > %BACKUP_DIR%\%DB_NAME%_%DATE_FORMAT%.dump

rem Or for all databases
rem pg_dumpall -U postgres > %BACKUP_DIR%\all_dbs_%DATE_FORMAT%.sql

echo Backup completed at %time% >> %LOG_DIR%\backup_%DATE_FORMAT%.log

rem Cleanup old backups (keep last 30 days)
forfiles /p %BACKUP_DIR% /m *.dump /d -30 /c "cmd /c del @path" 2>NUL
```

2. Schedule the script:
   - Open Task Scheduler (taskschd.msc)
   - Click "Create Basic Task"
   - Name it "PostgreSQL Backup"
   - Set the trigger (e.g., Daily at 2:00 AM)
   - Action: Start a program
   - Program/script: Browse to your `backup_postgres.bat`
   - Finish the wizard

### Using PowerShell

Create a more advanced backup script with PowerShell (`backup_postgres.ps1`):

```powershell
# PostgreSQL backup PowerShell script
param(
    [string]$DbName = "your_database",
    [string]$BackupDir = "C:\PostgreSQL\backups",
    [string]$LogDir = "C:\PostgreSQL\logs",
    [int]$RetentionDays = 30
)

# Set PostgreSQL connection parameters
$env:PGPASSWORD = "yourpassword"
$PgDumpPath = "C:\Program Files\PostgreSQL\12\bin\pg_dump.exe"
$PgHost = "localhost"
$PgUser = "postgres"

# Create date-based filename
$Date = Get-Date -Format "yyyyMMdd"
$BackupFile = "$BackupDir\$DbName`_$Date.dump"
$LogFile = "$LogDir\backup_$Date.log"

# Create directories if they don't exist
if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir | Out-Null }
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }

# Log start time
"Backup started at $(Get-Date)" | Out-File -FilePath $LogFile -Append

# Perform backup
try {
    & $PgDumpPath -h $PgHost -U $PgUser -Fc -d $DbName -f $BackupFile
    if ($LASTEXITCODE -eq 0) {
        "Backup completed successfully at $(Get-Date)" | Out-File -FilePath $LogFile -Append
    } else {
        "Backup failed with exit code $LASTEXITCODE" | Out-File -FilePath $LogFile -Append
    }
} catch {
    "Error: $_" | Out-File -FilePath $LogFile -Append
}

# Validate backup file
if (Test-Path $BackupFile) {
    $FileSize = (Get-Item $BackupFile).Length
    "Backup file size: $([math]::Round($FileSize/1MB, 2)) MB" | Out-File -FilePath $LogFile -Append
} else {
    "ERROR: Backup file not created!" | Out-File -FilePath $LogFile -Append
}

# Clean up old backups
Get-ChildItem -Path $BackupDir -Filter "*.dump" | 
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$RetentionDays) } | 
    ForEach-Object {
        "Removing old backup: $($_.FullName)" | Out-File -FilePath $LogFile -Append
        Remove-Item $_.FullName
    }
```

Schedule this PowerShell script with Task Scheduler, setting the action to:
- Program/script: `powershell.exe`
- Arguments: `-ExecutionPolicy Bypass -File "C:\path\to\backup_postgres.ps1"`

### Using Windows Services for WAL Archiving Monitoring

Create a simple PowerShell script to monitor WAL archiving:

```powershell
# Check WAL archiving status
param(
    [string]$LogDir = "C:\PostgreSQL\logs",
    [string]$ArchiveDir = "C:\archivedir",
    [int]$AlertThresholdMinutes = 30
)

$LogFile = "$LogDir\wal_monitor_$(Get-Date -Format 'yyyyMMdd').log"

# Check if archive directory exists
if (-not (Test-Path $ArchiveDir)) {
    "ERROR: Archive directory does not exist!" | Out-File -FilePath $LogFile -Append
    exit 1
}

# Check the most recent WAL file
$LatestWAL = Get-ChildItem -Path $ArchiveDir | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($null -eq $LatestWAL) {
    "WARNING: No WAL files found in archive directory!" | Out-File -FilePath $LogFile -Append
    exit 1
}

$TimeSinceLastWAL = (Get-Date) - $LatestWAL.LastWriteTime
$MinutesSinceLastWAL = $TimeSinceLastWAL.TotalMinutes

"Last WAL file: $($LatestWAL.Name) created $([math]::Round($MinutesSinceLastWAL, 1)) minutes ago" | Out-File -FilePath $LogFile -Append

if ($MinutesSinceLastWAL -gt $AlertThresholdMinutes) {
    "ALERT: No new WAL files in the last $AlertThresholdMinutes minutes!" | Out-File -FilePath $LogFile -Append
    # Add code to send email or other alerts here
    exit 1
}

"WAL archiving appears to be working normally" | Out-File -FilePath $LogFile -Append
exit 0
```

## PostgreSQL 16 Changes

PostgreSQL 16 introduces several improvements to backup and recovery. Here are the key differences compared to PostgreSQL 12:

### Recovery Configuration Changes

1. **Recovery Configuration Files**:
   - In PostgreSQL 16, recovery parameters are primarily set in `postgresql.conf`, not in a separate recovery.conf file
   - The `recovery.signal` and `standby.signal` files are used to trigger recovery mode (as already adopted in PG12)

2. **New Recovery Parameters**:
   - `recovery_target_action`: Additional options including 'pause', 'promote', 'shutdown'
   - Enhanced parallel restore capabilities with higher default values

### New Features and Improvements

1. **Incremental Backup Support**:
   - PostgreSQL 16 adds better support for incremental backups
   - New function: `pg_backup_start()` now supports format parameter for improved integration with backup tools
   - Improved block-level tracking for more efficient incremental backups

2. **Logical Replication Improvements**:
   - Better handling of large transactions
   - Two-phase commit support for logical replication
   - These improvements can be used for backup strategies in large databases

3. **pg_basebackup Enhancements**:
   - Improved compression options
   - Better error handling and recovery
   - New parameters for finer control:
     ```shell
     pg_basebackup -d "postgresql://postgres@localhost" -D C:\backup -X stream -Z 9 --compression-method=gzip
     ```

4. **WAL Improvements**:
   - More efficient WAL logging
   - Better performance for WAL archiving
   - Enhanced WAL prefetch capabilities

5. **Replication Slot Improvements**:
   - Better management of replication slots
   - Enhanced monitoring capabilities

### Updated Command Syntax

1. **pg_dump**:
   ```shell
   # PostgreSQL 16 supports more powerful filtering
   pg_dump -U postgres -d <database-name> --exclude-table-data='log_*' > C:\path\to\backup.sql
   ```

2. **WAL Archiving**:
   ```
   # In postgresql.conf, prefer to use %p and %f consistently
   archive_command = 'copy "%p" "C:\\archivedir\\%f"'
   
   # Better handling of archive failures
   archive_cleanup_command = 'pg_archivecleanup C:\\archivedir %r'
   ```

3. **Updated Function Names**:
   - `pg_current_wal_lsn()` (already in PG12) fully replaces the older `pg_current_xlog_location()`
   - Some more advanced WAL functions have been added

### Recovery Commands:

```sql
-- Check recovery progress (improved in PG16)
SELECT pg_is_in_recovery(), pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn();

-- More effective monitoring queries available in PG16
SELECT * FROM pg_stat_recovery_prefetch;  -- New in PG16
```

### Recommended Default Settings for PostgreSQL 16

```
# High-performance WAL settings for PG16
wal_level = replica
synchronous_commit = off  # For non-critical workloads to improve performance
wal_compression = on      # Better compression in PG16
```

For PostgreSQL 16, these backup procedures remain largely the same, but the performance, flexibility, and reliability have been improved.

## Production-Ready Backup Plan (Compressed Version)

This is a condensed, production-ready implementation of the concepts described above.

### 1. Setup WAL Archiving

```shell
# Stop PostgreSQL
pg_ctl stop

# Edit postgresql.conf
wal_level = replica
archive_mode = on
archive_command = 'copy "%p" "E:\\pgbackup\\archive\\%f"'
max_wal_senders = 3

# Create archive directory
mkdir E:\pgbackup\archive

# Start PostgreSQL
pg_ctl start

# Verify
psql -U postgres -c "SELECT pg_switch_wal();"
```

### 2. Base Backup Script (backup.ps1)

```powershell
# Daily base backup script
$date = Get-Date -Format "yyyyMMdd"
# Never store passwords in plain text in scripts!
# Instead, use Windows Credential Manager or a secure method
$backupDir = "E:\pgbackup\base\$date"
$logFile = "E:\pgbackup\logs\backup_$date.log"

# Create directories
New-Item -ItemType Directory -Path $backupDir -Force
New-Item -ItemType Directory -Path "E:\pgbackup\logs" -Force

# Log start
"Backup started: $(Get-Date)" | Out-File $logFile

# Take base backup
& "C:\Program Files\PostgreSQL\16\bin\pg_basebackup.exe" -h localhost -U postgres -D $backupDir -Ft -z -X stream -P | Out-File $logFile -Append

# Verify backup
if (Test-Path "$backupDir\base.tar.gz") {
    "Backup successful: $(Get-Date)" | Out-File $logFile -Append
} else {
    "BACKUP FAILED: $(Get-Date)" | Out-File $logFile -Append
    # Email alert (using Send-MailMessage or another method)
}

# Cleanup old backups (keep 7 days)
Get-ChildItem "E:\pgbackup\base" -Directory | Where-Object {
    $_.LastWriteTime -lt (Get-Date).AddDays(-7)
} | Remove-Item -Recurse -Force
```

### 3. WAL Archive Cleanup Script (cleanup_wal.ps1)

```powershell
# Run after successful base backup
# Never store passwords in plain text in scripts!
# Instead, use Windows Credential Manager or a secure method
$latestBackup = Get-ChildItem "E:\pgbackup\base" -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1

# Get the oldest WAL needed
$query = "SELECT pg_walfile_name(pg_backup_start_time());"
$oldestWalFile = & "C:\Program Files\PostgreSQL\16\bin\psql.exe" -h localhost -U postgres -t -c $query

# Clean obsolete WAL files
Get-ChildItem "E:\pgbackup\archive" | Where-Object {
    $_.Name -lt $oldestWalFile
} | Remove-Item -Force

# Log cleanup activity
"Cleaned WAL files older than $oldestWalFile" | Out-File "E:\pgbackup\logs\wal_cleanup_$(Get-Date -Format 'yyyyMMdd').log"
```

### 4. Backup Validation Script (validate.ps1)

```powershell
# Weekly backup validation
# Never store passwords in plain text in scripts!
# Instead, use Windows Credential Manager or a secure method
$logFile = "E:\pgbackup\logs\validation_$(Get-Date -Format 'yyyyMMdd').log"
$latestBackup = Get-ChildItem "E:\pgbackup\base" -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1

# Log start
"Validation started: $(Get-Date)" | Out-File $logFile

# Test restore to temporary location
$testDir = "E:\pgbackup\test_restore"
New-Item -ItemType Directory -Path $testDir -Force

# Extract latest backup
tar -xzf "$($latestBackup.FullPath)\base.tar.gz" -C $testDir

# Create recovery.signal
"" | Out-File "$testDir\recovery.signal"

# Create recovery conf
@"
restore_command = 'copy "E:\\pgbackup\\archive\\%f" "%p"'
recovery_target = 'immediate'
"@ | Out-File "$testDir\postgresql.conf" -Append

# Test start (with different port)
& "C:\Program Files\PostgreSQL\16\bin\pg_ctl.exe" -D $testDir -o "-p 5433" start | Out-File $logFile -Append

# Wait and check
Start-Sleep -Seconds 30
$result = & "C:\Program Files\PostgreSQL\16\bin\pg_isready.exe" -h localhost -p 5433

if ($LASTEXITCODE -eq 0) {
    "Validation SUCCESSFUL: $(Get-Date)" | Out-File $logFile -Append
} else {
    "Validation FAILED: $(Get-Date)" | Out-File $logFile -Append
    # Send alert email
}

# Stop test instance
& "C:\Program Files\PostgreSQL\16\bin\pg_ctl.exe" -D $testDir stop | Out-File $logFile -Append

# Clean up
Remove-Item -Path $testDir -Recurse -Force
```

### 5. Monitoring Script (monitor.ps1)

```powershell
# Run every 15 minutes
# Never store passwords in plain text in scripts!
# Instead, use Windows Credential Manager or a secure method
$logFile = "E:\pgbackup\logs\monitor_$(Get-Date -Format 'yyyyMMdd').log"

# Check archives
$latestWal = Get-ChildItem "E:\pgbackup\archive" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$walAge = (Get-Date) - $latestWal.LastWriteTime

if ($walAge.TotalMinutes -gt 30) {
    "ALERT: No recent WAL files! Last file: $($latestWal.Name) from $($latestWal.LastWriteTime)" | Out-File $logFile -Append
    # Send alert email
}

# Check backup success
$latestBackupLog = Get-ChildItem "E:\pgbackup\logs" -Filter "backup_*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$backupSuccess = Select-String -Path $latestBackupLog.FullName -Pattern "Backup successful"

if (-not $backupSuccess) {
    "ALERT: Last backup may have failed! Check $($latestBackupLog.Name)" | Out-File $logFile -Append
    # Send alert email
}
```

### 6. Task Scheduler Setup

```powershell
# Schedule daily backup (1:00 AM)
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File E:\pgbackup\scripts\backup.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At "01:00"
Register-ScheduledTask -TaskName "PostgreSQL Daily Backup" -Action $action -Trigger $trigger -RunLevel Highest -User "SYSTEM"

# Schedule WAL cleanup (2:00 AM)
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File E:\pgbackup\scripts\cleanup_wal.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At "02:00"
Register-ScheduledTask -TaskName "PostgreSQL WAL Cleanup" -Action $action -Trigger $trigger -RunLevel Highest -User "SYSTEM"

# Schedule weekly validation (Sunday 3:00 AM)
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File E:\pgbackup\scripts\validate.ps1"
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At "03:00"
Register-ScheduledTask -TaskName "PostgreSQL Backup Validation" -Action $action -Trigger $trigger -RunLevel Highest -User "SYSTEM"

# Schedule monitoring (every 15 minutes)
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File E:\pgbackup\scripts\monitor.ps1"
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 15)
Register-ScheduledTask -TaskName "PostgreSQL Backup Monitoring" -Action $action -Trigger $trigger -RunLevel Highest -User "SYSTEM"
```

### 7. Recovery Procedure (DR.md)

1. Stop PostgreSQL service
2. Restore latest base backup:
   ```shell
   tar -xzf "E:\pgbackup\base\latest_date\base.tar.gz" -C "C:\Program Files\PostgreSQL\16\data"
   ```
3. Add to postgresql.conf:
   ```
   restore_command = 'copy "E:\\pgbackup\\archive\\%f" "%p"'
   ```
4. Create recovery.signal file:
   ```shell
   type nul > "C:\Program Files\PostgreSQL\16\data\recovery.signal"
   ```
5. Start PostgreSQL service
6. Complete recovery:
   ```sql
   SELECT pg_wal_replay_resume();
   ```

### 8. Secure Credential Management

Instead of storing passwords in plain text, use one of these secure approaches:

#### Option 1: pgpass File (Simplest)
```powershell
# Create a .pgpass file in the Windows user profile
$pgpassContent = "localhost:5432:*:postgres:YourSecurePassword"
$pgpassPath = "$env:USERPROFILE\AppData\Roaming\postgresql\pgpass.conf"

# Create directory if it doesn't exist
New-Item -ItemType Directory -Path "$env:USERPROFILE\AppData\Roaming\postgresql" -Force

# Create .pgpass file with restricted permissions
$pgpassContent | Out-File -FilePath $pgpassPath -Encoding ASCII
# Secure the file - PowerShell equivalent of chmod 600
$acl = Get-Acl $pgpassPath
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    [System.Security.Principal.WindowsIdentity]::GetCurrent().Name,
    "FullControl",
    "Allow"
)
$acl.SetAccessRule($accessRule)
Set-Acl $pgpassPath $acl
```

#### Option 2: Windows Credential Manager
```powershell
# First-time setup: Store credentials securely (run once interactively)
# Requires cmdlet from: Install-Module -Name CredentialManager
New-StoredCredential -Target "PostgreSQL" -UserName "postgres" -Password "YourSecurePassword" -Type Generic -Persist LocalMachine

# Then in your scripts, retrieve credentials:
function Get-PostgresCredential {
    $cred = Get-StoredCredential -Target "PostgreSQL"
    if ($cred) {
        return $cred
    } else {
        throw "PostgreSQL credentials not found in Windows Credential Manager"
    }
}

# Example usage in backup script
$credential = Get-PostgresCredential
$env:PGPASSWORD = $credential.GetNetworkCredential().Password
try {
    # Run your backup commands here
    & pg_basebackup.exe -h localhost -U $credential.UserName -D $backupDir -Ft -z -X stream
} finally {
    # Clear password from environment
    $env:PGPASSWORD = ""
}
```

#### Option 3: Encrypted Configuration File
```powershell
# First-time setup: Create and encrypt config file (run once)
@{
    PostgreSQL = @{
        UserName = "postgres"
        Password = "YourSecurePassword"
    }
} | ConvertTo-Json | ConvertTo-SecureString -AsPlainText -Force | 
  ConvertFrom-SecureString | 
  Out-File "E:\pgbackup\config\secure_config.xml"

# In your scripts, decrypt and use:
function Get-SecureConfig {
    $encryptedConfig = Get-Content "E:\pgbackup\config\secure_config.xml" | ConvertTo-SecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($encryptedConfig)
    $decryptedConfig = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    return $decryptedConfig | ConvertFrom-Json
}

# Example usage
$config = Get-SecureConfig
$env:PGPASSWORD = $config.PostgreSQL.Password
try {
    # Run your backup commands
} finally {
    # Clear password
    $env:PGPASSWORD = ""
}
```

### 9. Additional Security Considerations

1. Use a dedicated service account with minimal permissions for backups
2. Encrypt all offsite or cloud-stored backups
3. Implement strict file permissions on backup directories
4. Log all backup operations and access attempts
5. Regularly rotate credentials
6. Use network security to restrict access to backup repositories
7. Implement multi-factor authentication for backup management access

## Best Practices

1. **Test your backups regularly** - The only reliable backup is one you have successfully restored
2. **Automate everything** - Human error is eliminated with proper automation
3. **Monitor and alert** - Be notified immediately when backups fail or WAL archiving stops
4. **Document procedures** - Create step-by-step recovery instructions for all scenarios
5. **Implement 3-2-1 backup strategy** - 3 copies, 2 different media types, 1 offsite
6. **Secure credentials** - Never store plain text passwords in scripts
7. **Version control** - Keep your backup scripts in source control
8. **Simulate failures** - Practice disaster recovery scenarios regularly
9. **Keep backup history** - Maintain logs of all backup and restore operations
10. **Stay current** - Update backup procedures when upgrading PostgreSQL versions

