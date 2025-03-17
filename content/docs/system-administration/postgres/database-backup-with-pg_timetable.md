## Windows

### install pg_timetable.exe and nssm

Download binary from the releases page in github [releases](https://github.com/cybertec-postgresql/pg_timetable/releases)
Unzip and install in a path directory (I have used C:\bin for all binaries in ktpv-prod-db01)

Get nssm from the web, perhaps from here (2025)
```ps1
Invoke-WebRequest -Uri https://nssm.cc/ci/nssm-2.24-101-g897c7ad.zip -OutFile "nssm.zip"
```
Move nssm.exe to path (in my case C:\bin)

run pg_timetable from powershell one time to establish the pg_timetable tables
```ps1
# remember to replace placeholders for password and database name
pg_timetable.exe --host=localhost --port=5432 --dbname=your_database --user=scheduler --password=somestrong --clientname=backup_worker
```
this creates a new schema called `timetable`


### Set up pg_timetable in desired database

Create a schedule user to run schedules on the desired database.

```sql
-- Remember to replace placeholders for password and database name
DROP ROLE IF EXISTS scheduler;

-- Create the role with proper permissions
CREATE ROLE scheduler WITH 
  LOGIN 
  PASSWORD 'somestrong'
  NOSUPERUSER
  NOCREATEDB
  NOCREATEROLE;

-- Grant necessary privileges
GRANT CREATE ON DATABASE your_database_name TO scheduler;
```
```sql
-- Create the backup job
SELECT timetable.add_job(
  'daily-backup-with-teams-notification',     -- job_name
  '0 3 * * *',                               -- job_schedule (3:00 AM daily)
  'powershell',                              -- job_command
  '["-File", "C:\\scripts\\backup_and_notify.ps1", "-dbName", "your_database", "-backupDir", "C:\\backups", "-teamsWebhookUrl", "https://outlook.office.com/webhook/your-webhook-url"]'::jsonb,  -- job_parameters
  'PROGRAM'                                   -- job_kind
);
```


### Create backup script
I use `C:\scripts` to collect powershell scripts on servers.

This script back ups the database, has error handling, and sends report to `MS Teams` webhook

```ps1
param (
    [string]$dbName = "your_database",
    [string]$backupDir = "C:\backups",
    [string]$teamsWebhookUrl = "https://outlook.office.com/webhook/your-webhook-url"
)

# Create timestamp for filename
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = "$backupDir\$dbName`_$timestamp.backup"

# Ensure backup directory exists
if (-not (Test-Path -Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir | Out-Null
}

# Variables to track status
$success = $false
$errorMessage = ""
$startTime = Get-Date
$endTime = $null
$duration = $null

try {
    # Run pg_dump to create the backup
    # Adjust the path to pg_dump.exe if needed
    $pgDumpPath = "C:\Program Files\PostgreSQL\16\bin\pg_dump.exe" 
    
    & $pgDumpPath --host=localhost --port=5432 --username=postgres --format=custom --file=$backupFile $dbName
    
    if ($LASTEXITCODE -eq 0) {
        $success = $true
        
        # Clean up old backups (optional - keep last 7 days)
        Get-ChildItem -Path $backupDir -Filter "$dbName*.backup" | 
            Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } | 
            Remove-Item -Force
    } else {
        $errorMessage = "pg_dump exited with code $LASTEXITCODE"
    }
} catch {
    $errorMessage = $_.Exception.Message
}

# Calculate execution time
$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

# Prepare Teams message
$backupSize = if ($success) { "{0:N2} MB" -f ((Get-Item $backupFile).Length / 1MB) } else { "N/A" }
$status = if ($success) { "✅ Success" } else { "❌ Failed" }
$color = if ($success) { "00ff00" } else { "ff0000" }

$body = @{
    "@type"      = "MessageCard"
    "@context"   = "http://schema.org/extensions"
    "themeColor" = $color
    "summary"    = "Database Backup $status"
    "sections"   = @(
        @{
            "activityTitle"    = "PostgreSQL Backup Report"
            "activitySubtitle" = "Generated on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            "facts"            = @(
                @{
                    "name"  = "Status"
                    "value" = $status
                },
                @{
                    "name"  = "Database"
                    "value" = $dbName
                },
                @{
                    "name"  = "Backup File"
                    "value" = $(Split-Path $backupFile -Leaf)
                },
                @{
                    "name"  = "Backup Size"
                    "value" = $backupSize
                },
                @{
                    "name"  = "Duration"
                    "value" = "$duration seconds"
                }
            )
        }
    )
}

if (-not $success) {
    $body.sections[0].facts += @{
        "name"  = "Error"
        "value" = $errorMessage
    }
}

# Send to Teams webhook
$jsonBody = $body | ConvertTo-Json -Depth 4
Invoke-RestMethod -Method Post -ContentType 'application/json' -Body $jsonBody -Uri $teamsWebhookUrl

# Output result for pg_timetable logging
if ($success) {
    Write-Output "Backup completed successfully: $backupFile ($backupSize)"
    exit 0
} else {
    Write-Output "Backup failed: $errorMessage"
    exit 1
}
```

### Install pg_timetable with nssm
open cmd as admin and run
```cmd
nssm install pg_timetable
```

in the dialog input

Path: `C:\bin\pg_timetable.exe`
Arguments: `--host=localhost --port=5432 --dbname=your_database --user=scheduler --password=somestrong --clientname=backup_worker`
Service name: `pg_timetable`
Startup type: `Automatic`

start the service with
```ps1
 start pg_timetable
```

### Verification
Check that the service is running
```ps1
sc query pg_timetable
```

Verify the job is registered in the database
```sql
SELECT * FROM timetable.chain WHERE chain_name = 'daily-backup-with-teams-notification';
```
Test run the job immediately
```ps1
SELECT timetable.execute_chain((SELECT chain_id FROM timetable.chain WHERE chain_name = 'daily-backup-with-teams-notification'));
```






