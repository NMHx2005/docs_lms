<#
  LMS MongoDB Restore Script (PowerShell)
  - Khôi phục từ file nén .archive.gz do mongodump tạo (backup.ps1)
  - Tự động chọn bản mới nhất nếu không truyền đường dẫn cụ thể
  - Kiểm tra checksum (nếu có file .json kèm theo)

  Cách dùng (PowerShell):
    # Thiết lập biến môi trường (tuỳ chọn)
    $env:MONGO_URI = "mongodb://localhost:27017"
    $env:DB_NAME = "lms"
    $env:BACKUP_ROOT = "D:\Backups\mongodb"

    # Khôi phục bản mới nhất của DB_NAME
    powershell -NoProfile -ExecutionPolicy Bypass -File ".\document_database\backup\restore.ps1" -Drop

    # Khôi phục từ file chỉ định
    powershell -NoProfile -ExecutionPolicy Bypass -File ".\document_database\backup\restore.ps1" `
      -ArchivePath "D:\Backups\mongodb\lms-20250101_013000.archive.gz" -Drop

  Lưu ý:
    - Tham số -Drop sẽ xoá dữ liệu hiện tại của DB trước khi restore (mongorestore --drop)
    - Với MongoDB Atlas, đặt $env:MONGO_URI thành SRV URI hoặc dùng tham số -MONGO_URI khi gọi script


    Atlas (SRV URI)
    powershell -NoProfile -ExecutionPolicy Bypass -File ".\document_database\backup\backup.ps1" `
        -MONGO_URI "mongodb+srv://hungnguyen18812:A5fd0lcDdMPeXg7Y@cluster0.cry5hnt.mongodb.net" `
        -DB_NAME "lms" `
        -BACKUP_ROOT "D:\Backups\mongodb" `
        -RETENTION_DAYS 7


    Lên lịch hằng ngày (01:30) với Task Scheduler
    schtasks /Create /TN "LMS MongoDB Daily Backup" /SC DAILY /ST 01:30 /RL LIMITED /F ^
    /TR "powershell -NoProfile -ExecutionPolicy Bypass -File \"D:\Self learning\CODE WEB\CodeThue\Learning_Management_System\document_database\backup\backup.ps1\" -MONGO_URI \"mongodb://localhost:27017\" -DB_NAME \"lms\" -BACKUP_ROOT \"D:\Backups\mongodb\" -RETENTION_DAYS 7"

#>

param(
  [string]$MONGO_URI = $env:MONGO_URI,
  [string]$DB_NAME = $env:DB_NAME,
  [string]$BACKUP_ROOT = $env:BACKUP_ROOT,
  [string]$ArchivePath,
  [switch]$Drop
)

if (-not $MONGO_URI -or $MONGO_URI.Trim() -eq '') { $MONGO_URI = 'mongodb://localhost:27017' }
if (-not $DB_NAME -or $DB_NAME.Trim() -eq '') { $DB_NAME = 'lms' }
if (-not $BACKUP_ROOT -or $BACKUP_ROOT.Trim() -eq '') { $BACKUP_ROOT = Join-Path $PSScriptRoot 'artifacts' }

# Tìm file backup mới nhất nếu không chỉ định ArchivePath
if (-not $ArchivePath -or $ArchivePath.Trim() -eq '') {
  $latest = Get-ChildItem -Path $BACKUP_ROOT -Filter ("{0}-*.archive.gz" -f $DB_NAME) -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
  if (-not $latest) {
    Write-Error "Không tìm thấy file backup trong '$BACKUP_ROOT' với pattern '${DB_NAME}-*.archive.gz'"
    exit 1
  }
  $ArchivePath = $latest.FullName
}

if (-not (Test-Path $ArchivePath)) {
  Write-Error "ArchivePath không tồn tại: $ArchivePath"
  exit 1
}

$logPath = Join-Path $BACKUP_ROOT ("restore-{0}-{1}.log.txt" -f $DB_NAME, (Get-Date -Format 'yyyyMMdd_HHmmss'))
try { Start-Transcript -Path $logPath -Append | Out-Null } catch {}

function Write-Info([string]$msg) { Write-Host "[restore] $msg" }

try {
  Write-Info "DB_NAME = $DB_NAME"
  Write-Info "MONGO_URI = $MONGO_URI"
  Write-Info "BACKUP_ROOT = $BACKUP_ROOT"
  Write-Info "ARCHIVE = $ArchivePath"
  Write-Info "DROP = $($Drop.IsPresent)"

  # Kiểm tra mongorestore
  $mongorestore = Get-Command mongorestore -ErrorAction SilentlyContinue
  if (-not $mongorestore) { throw 'mongorestore not found in PATH. Please install MongoDB Database Tools.' }

  # Kiểm tra checksum nếu có file metadata .json
  $metaPath = $ArchivePath + '.json'
  if (Test-Path $metaPath) {
    try {
      $meta = Get-Content -Path $metaPath -Raw | ConvertFrom-Json
      if ($meta.sha256) {
        $sha = Get-FileHash -Path $ArchivePath -Algorithm SHA256
        if ($sha.Hash -ne $meta.sha256) {
          Write-Warning "Checksum mismatch! File: $($sha.Hash) <> Meta: $($meta.sha256)"
        } else {
          Write-Info "Checksum OK ($($sha.Hash.Substring(0,12))...)"
        }
      }
    } catch { Write-Warning "Không đọc được metadata: $metaPath" }
  } else {
    Write-Info "Không có metadata .json kèm theo, bỏ qua kiểm tra checksum"
  }

  # Thực thi mongorestore
  $args = @('--uri', $MONGO_URI, '--db', $DB_NAME, '--archive', $ArchivePath, '--gzip')
  if ($Drop.IsPresent) { $args += '--drop' }

  Write-Info ("mongorestore " + ($args -join ' '))
  & mongorestore @args
  if ($LASTEXITCODE -ne 0) { throw "mongorestore failed with exit code $LASTEXITCODE" }

  Write-Info "Restore OK"
  exit 0
}
catch {
  Write-Error $_
  exit 1
}
finally {
  try { Stop-Transcript | Out-Null } catch {}
}
