<#
  LMS MongoDB Backup Script (PowerShell)
  - Tạo file nén .archive.gz bằng mongodump --archive --gzip
  - Lưu metadata (SHA256, timestamp, retention)
  - Xoay vòng (xóa backup cũ theo RETENTION_DAYS)

  Cách dùng (PowerShell):
    # Thiết lập biến môi trường (tuỳ chọn)
    $env:MONGO_URI = "mongodb://localhost:27017"
    $env:DB_NAME = "lms"
    $env:BACKUP_ROOT = "D:\Backups\mongodb"
    $env:RETENTION_DAYS = "7"

    # Chạy backup
    powershell -NoProfile -ExecutionPolicy Bypass -File ".\document_database\backup\backup.ps1"

  Lịch (Windows Task Scheduler) ví dụ (chạy 01:30 mỗi ngày):
    schtasks /Create /TN "LMS MongoDB Daily Backup" /SC DAILY /ST 01:30 ^
      /TR "powershell -NoProfile -ExecutionPolicy Bypass -File \"D:\Path\to\Learning_Management_System\document_database\backup\backup.ps1\"" /RL LIMITED /F

  Khôi phục (restore) ví dụ:
    mongorestore --uri "mongodb://localhost:27017" --db lms ^
      --archive="D:\Backups\mongodb\lms-20250101_013000.archive.gz" --gzip --drop
#>

param(
  [string]$MONGO_URI = $env:MONGO_URI,
  [string]$DB_NAME = $env:DB_NAME,
  [string]$BACKUP_ROOT = $env:BACKUP_ROOT,
  [int]$RETENTION_DAYS = [int]($env:RETENTION_DAYS)
)

if (-not $MONGO_URI -or $MONGO_URI.Trim() -eq '') { $MONGO_URI = 'mongodb://localhost:27017' }
if (-not $DB_NAME -or $DB_NAME.Trim() -eq '') { $DB_NAME = 'lms' }
if (-not $BACKUP_ROOT -or $BACKUP_ROOT.Trim() -eq '') { $BACKUP_ROOT = Join-Path $PSScriptRoot 'artifacts' }
if (-not $RETENTION_DAYS -or $RETENTION_DAYS -le 0) { $RETENTION_DAYS = 7 }

# Tạo thư mục đích
New-Item -ItemType Directory -Force -Path $BACKUP_ROOT | Out-Null

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$archivePath = Join-Path $BACKUP_ROOT ("{0}-{1}.archive.gz" -f $DB_NAME, $timestamp)
$logPath = Join-Path $BACKUP_ROOT ("{0}-{1}.log.txt" -f $DB_NAME, $timestamp)

# Bắt đầu ghi log transcript
try { Start-Transcript -Path $logPath -Append | Out-Null } catch {}

function Write-Info([string]$msg) { Write-Host "[backup] $msg" }

try {
  Write-Info "DB_NAME = $DB_NAME"
  Write-Info "MONGO_URI = $MONGO_URI"
  Write-Info "BACKUP_ROOT = $BACKUP_ROOT"
  Write-Info "RETENTION_DAYS = $RETENTION_DAYS"
  Write-Info "Archive file = $archivePath"

  # Kiểm tra mongodump
  $mongodump = Get-Command mongodump -ErrorAction SilentlyContinue
  if (-not $mongodump) { throw 'mongodump not found in PATH. Please install MongoDB Database Tools.' }

  # Thực thi mongodump --archive --gzip
  & mongodump --uri "$MONGO_URI" --db "$DB_NAME" --archive="$archivePath" --gzip
  if ($LASTEXITCODE -ne 0) { throw "mongodump failed with exit code $LASTEXITCODE" }

  # Tạo checksum và metadata
  $sha = Get-FileHash -Path $archivePath -Algorithm SHA256
  $meta = @{ 
    db = $DB_NAME
    uri = $MONGO_URI
    archive = $archivePath
    sha256 = $sha.Hash
    createdAt = (Get-Date).ToString('o')
    retentionDays = $RETENTION_DAYS
  } | ConvertTo-Json -Depth 3
  Set-Content -Path ($archivePath + '.json') -Value $meta -Encoding UTF8

  Write-Info "Backup OK → $archivePath"

  # Xoay vòng: xoá file cũ quá hạn
  $cutoff = (Get-Date).AddDays(-$RETENTION_DAYS)
  $old = Get-ChildItem -Path $BACKUP_ROOT -Filter ("{0}-*.archive.gz" -f $DB_NAME) |
    Where-Object { $_.CreationTime -lt $cutoff }
  foreach ($f in $old) {
    Write-Info "Remove old backup: $($f.FullName)"
    Remove-Item $f.FullName -Force -ErrorAction SilentlyContinue
    $metaFile = $f.FullName + '.json'
    if (Test-Path $metaFile) { Remove-Item $metaFile -Force -ErrorAction SilentlyContinue }
  }

  exit 0
}
catch {
  Write-Error $_
  exit 1
}
finally {
  try { Stop-Transcript | Out-Null } catch {}
}
