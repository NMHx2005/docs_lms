## Hướng dẫn cấu hình và chạy Backup/Restore MongoDB (Windows)

Tài liệu này hướng dẫn cấu hình và chạy hệ thống backup/restore MongoDB đã tích hợp trong dự án, dành cho Windows/PowerShell. Bao gồm lý do từng bước, ví dụ đường dẫn, và mục xử lý lỗi thường gặp.

- Script backup: `document_database/backup/backup.ps1`
- Script restore: `document_database/backup/restore.ps1`
- Wrapper chạy theo lịch: `document_database/backup/run_backup.cmd`

Lưu ý: Mỗi máy có đường dẫn lưu trữ khác nhau. Ví dụ trong tài liệu sẽ dùng `D:\Backups\mongodb`. Bạn có thể thay thành thư mục khác (VD: `E:\MongoBackups` hoặc `C:\Data\db-backups`).

---

## 1) Chuẩn bị môi trường (vì sao cần)

- Cần MongoDB Database Tools để có lệnh `mongodump`/`mongorestore` (script backup/restore dùng các lệnh này).
- Cần PowerShell để chạy script `.ps1`.

### Cài đặt và xác minh
1. Cài bản MSI: `mongodb-database-tools-windows-x86_64-<version>.msi` (đã cài 100.12.2).
2. Mở PowerShell mới và kiểm tra:
   ```powershell
   mongodump --version
   ```
   - Nếu “not recognized” → PATH chưa có công cụ.

### Thêm Tools vào PATH (lý do: để task và phiên PowerShell gọi được mongodump)
- Tìm vị trí cài:
  ```powershell
  $dump = Get-ChildItem "C:\Program Files" -Recurse -Filter mongodump.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
  $dump
  ```
- Thêm PATH tạm thời cho phiên hiện tại:
  ```powershell
  $toolDir = Split-Path $dump
  $env:Path = "$toolDir;$env:Path"
  mongodump --version
  ```
- (Tuỳ chọn) Thêm PATH vĩnh viễn rồi mở PowerShell mới:
  ```powershell
  setx PATH "$env:PATH;$toolDir"
  ```

---

## 2) Thiết lập thư mục lưu backup (vì sao cần)

- Cần nơi lưu file `.archive.gz` và log để kiểm tra sau này.
- Ví dụ dùng `D:\Backups\mongodb`:
  ```powershell
  New-Item -ItemType Directory -Force -Path "D:\Backups\mongodb" | Out-Null
  ```
  Thay đổi tuỳ máy (VD: `E:\MongoBackups`). Update tham số `-BACKUP_ROOT` theo thư mục bạn chọn.

---

## 3) Chạy backup thủ công (kiểm tra lần đầu)

- Tại thư mục dự án:
  ```powershell
  cd "D:\Self learning\CODE WEB\CodeThue\Learning_Management_System"
  powershell -NoProfile -ExecutionPolicy Bypass -File ".\document_database\backup\backup.ps1" `
    -MONGO_URI "mongodb://localhost:27017" `
    -DB_NAME "lms" `
    -BACKUP_ROOT "D:\Backups\mongodb" `
    -RETENTION_DAYS 7
  ```
  - Với MongoDB Atlas, thay `-MONGO_URI` bằng SRV URI: `mongodb+srv://USER:PASS@CLUSTER.mongodb.net`.

Kết quả mong đợi: sinh file `lms-YYYYMMDD_HHMMSS.archive.gz` và `.json` (metadata) trong thư mục backup, kèm `.log.txt`.

Lý do: chạy tay 1 lần để chắc chắn PATH/URI/permission ổn trước khi cấu hình chạy tự động.

---

## 4) Lên lịch backup hằng ngày bằng Task Scheduler

### Cách A (đề xuất): dùng wrapper `.cmd` để tránh lỗi quote/PATH
- File: `document_database/backup/run_backup.cmd` (đã có trong repo)
  ```cmd
  @echo off
  set "PATH=C:\Program Files\MongoDB\Tools\100\bin;%PATH%"
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:\Self learning\CODE WEB\CodeThue\Learning_Management_System\document_database\backup\backup.ps1" -MONGO_URI "mongodb://localhost:27017" -DB_NAME "lms" -BACKUP_ROOT "D:\Backups\mongodb" -RETENTION_DAYS 7
  ```
  - Chỉnh đường dẫn cho phù hợp máy bạn (đặc biệt `-BACKUP_ROOT`).

- Tạo task (PowerShell):
  ```powershell
  $tr = "D:\Self learning\CODE WEB\CodeThue\Learning_Management_System\document_database\backup\run_backup.cmd"
  schtasks /Create /TN "LMS MongoDB Daily Backup" /SC DAILY /ST 01:30 /RL LIMITED /F /TR $tr
  ```
  - Lý do dùng `.cmd`: tránh vỡ quotes khi đường dẫn có dấu cách, và đảm bảo PATH mongodump có sẵn khi Task chạy.

- Chạy thử và kiểm tra:
  ```powershell
  schtasks /Run /TN "LMS MongoDB Daily Backup"
  Get-ChildItem "D:\Backups\mongodb" -Filter "lms-*.archive.gz" | Sort-Object LastWriteTime -Descending | Select -First 1
  ```

### Cách B: dùng GUI Task Scheduler
- Action → Program/script: `C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe`
- Add arguments:
  ```
  -NoProfile -ExecutionPolicy Bypass -File "D:\...\backup.ps1" -MONGO_URI "mongodb://localhost:27017" -DB_NAME "lms" -BACKUP_ROOT "D:\Backups\mongodb" -RETENTION_DAYS 7
  ```
- Start in: `D:\...\document_database\backup`
- “Run with highest privileges” nếu cần.

---

## 5) Restore dữ liệu khi cần

- Khôi phục bản mới nhất (local, xoá dữ liệu cũ trước khi restore):
  ```powershell
  $env:MONGO_URI="mongodb://localhost:27017"
  $env:DB_NAME="lms"
  $env:BACKUP_ROOT="D:\Backups\mongodb"
  powershell -NoProfile -ExecutionPolicy Bypass -File ".\document_database\backup\restore.ps1" -Drop
  ```

- Khôi phục từ file cụ thể:
  ```powershell
  powershell -NoProfile -ExecutionPolicy Bypass -File ".\document_database\backup\restore.ps1" `
    -ArchivePath "D:\Backups\mongodb\lms-20250101_013000.archive.gz" -Drop
  ```

Restore sẽ kiểm tra checksum nếu có file `.json` kèm theo.

---

## 6) Lý do & nguyên tắc vận hành

- Dùng `--archive --gzip`: tạo một file nén duy nhất, tiện lưu trữ/chuyển giao.
- Giữ metadata `.json` chứa SHA256: giúp xác thực file trước khi restore.
- Xoay vòng theo `RETENTION_DAYS`: tiết kiệm dung lượng, tự dọn file quá hạn.
- Wrapper `.cmd`: đảm bảo PATH mongodump tồn tại cả khi Task Scheduler không nạp biến môi trường người dùng.

---

## 7) Lỗi thường gặp và cách xử lý

### 7.1 `mongodump not found in PATH`
- Nguyên nhân: chưa cài Tools hoặc PATH chưa có.
- Khắc phục nhanh (phiên hiện tại):
  ```powershell
  $dump = Get-ChildItem "C:\Program Files" -Recurse -Filter mongodump.exe -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
  $toolDir = Split-Path $dump
  $env:Path = "$toolDir;$env:Path"
  mongodump --version
  ```
- Hoặc thêm vào wrapper `.cmd` (đã có dòng `set "PATH=..."`).

### 7.2 `ERROR: Invalid argument/option` khi tạo task với `/TR`
- Nguyên nhân: vỡ quotes do đường dẫn có dấu cách.
- Khắc phục: dùng biến `$tr` hoặc dùng wrapper `.cmd` như hướng dẫn ở mục 4.

### 7.3 Task chạy báo lỗi 0x1 (không tạo file)
- Nguyên nhân phổ biến: thiếu PATH mongodump khi chạy dưới Task Scheduler.
- Khắc phục: sửa `run_backup.cmd` để `set PATH` đúng; hoặc thêm Tools vào PATH hệ thống; hoặc dùng GUI điền đầy đủ.

### 7.4 Atlas kết nối lỗi
- Kiểm tra: SRV URI đúng, user/password đúng, IP máy đã được whitelist trong Network Access.

### 7.5 Dung lượng backup tăng nhanh
- Tăng `RETENTION_DAYS` hợp lý hoặc chuyển backup sang ổ khác có nhiều dung lượng.

### 7.6 Kiểm tra nhanh sau khi chạy
```powershell
Get-ChildItem "D:\Backups\mongodb" -Filter "lms-*.archive.gz" | Sort-Object LastWriteTime -Descending | Select -First 1
Get-ChildItem "D:\Backups\mongodb" -Filter "lms-*.log.txt" | Sort-Object LastWriteTime -Descending | Select -First 1 | Get-Content -Tail 50
```

---

## 8) Tuỳ biến theo máy và môi trường
- Thay đổi `-BACKUP_ROOT` theo thư mục của bạn (VD: `E:\MongoBackups`).
- Với Atlas, thay `-MONGO_URI` bằng URI SRV.
- Thời gian chạy task: thay `/ST 01:30` theo lịch bạn muốn (24h format).

---

## 9) FAQ
- Hỏi: Có thể backup nhiều DB cùng lúc? → Chạy script nhiều lần với `-DB_NAME` khác nhau hoặc sửa script để lặp.
- Hỏi: Có thể mã hoá file backup? → Lưu vào volume mã hoá (BitLocker) hoặc nén thêm bằng công cụ khác; script hiện dùng gzip tích hợp mongodump.
- Hỏi: Có thể gửi backup lên cloud? → Tạo bước upload bổ sung (VD: `aws s3 cp`) sau khi tạo file.

---

Nếu cần, có thể mở rộng script để gửi thông báo (email/Slack) khi backup/restore thành công hoặc thất bại.

## 10) Hướng dẫn riêng cho MongoDB Atlas

Atlas dùng SRV URI (`mongodb+srv://...`) và yêu cầu cấp quyền + whitelist IP. Phần này tổng hợp các bước và lỗi thường gặp khi chạy backup/restore với Atlas.

### 10.1 Chuẩn bị trên Atlas (lý do: xác thực và mạng)
1. Lấy SRV URI trong Atlas → "Connect" → "Drivers" (ví dụ):
   - `mongodb+srv://USER:PASS@CLUSTER.mongodb.net`
2. Tạo Database User (Database Access):
   - Quyền: `readWrite` cho database `lms` (nguyên tắc tối thiểu quyền).
3. Whitelist IP (Network Access):
   - "Add current IP address" để cho phép máy bạn truy cập.
   - Tránh `0.0.0.0/0` (chỉ dùng tạm khi thử nghiệm, kèm cảnh báo).
4. Kiểm tra kết nối nhanh:
   ```powershell
   mongosh "mongodb+srv://USER:PASS@CLUSTER.mongodb.net" --eval "db.runCommand({ ping: 1 })"
   ```

### 10.2 Backup thủ công với Atlas
Chạy script và truyền SRV URI qua tham số `-MONGO_URI`:
```powershell
cd "D:\Self learning\CODE WEB\CodeThue\Learning_Management_System"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\document_database\backup\backup.ps1" `
  -MONGO_URI "mongodb+srv://USER:PASS@CLUSTER.mongodb.net" `
  -DB_NAME "lms" `
  -BACKUP_ROOT "D:\Backups\mongodb" `
  -RETENTION_DAYS 7
```

Lưu ý đường dẫn `-BACKUP_ROOT` thay theo máy (VD: `E:\MongoBackups`).

### 10.3 Lập lịch backup Atlas bằng Task Scheduler (dùng wrapper)
Tạo file wrapper riêng cho Atlas (ví dụ `run_backup_atlas.cmd`) để tránh lỗi quote và đảm bảo PATH có mongodump:
```cmd
@echo off
set "PATH=C:\Program Files\MongoDB\Tools\100\bin;%PATH%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:\Self learning\CODE WEB\CodeThue\Learning_Management_System\document_database\backup\backup.ps1" -MONGO_URI "mongodb+srv://USER:PASS@CLUSTER.mongodb.net" -DB_NAME "lms" -BACKUP_ROOT "D:\Backups\mongodb" -RETENTION_DAYS 7
```
Tạo task (PowerShell):
```powershell
$tr = "D:\Self learning\CODE WEB\CodeThue\Learning_Management_System\document_database\backup\run_backup_atlas.cmd"
schtasks /Create /TN "LMS MongoDB Daily Backup (Atlas)" /SC DAILY /ST 01:30 /RL LIMITED /F /TR $tr
```

### 10.4 Restore với Atlas
- Khôi phục bản mới nhất về Atlas (cẩn trọng với `-Drop` vì sẽ xoá dữ liệu DB trước khi nạp lại):
```powershell
$env:MONGO_URI="mongodb+srv://USER:PASS@CLUSTER.mongodb.net"
$env:DB_NAME="lms"
$env:BACKUP_ROOT="D:\Backups\mongodb"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\document_database\backup\restore.ps1" -Drop
```
- Khôi phục từ file cụ thể lên Atlas:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\document_database\backup\restore.ps1" `
  -MONGO_URI "mongodb+srv://USER:PASS@CLUSTER.mongodb.net" `
  -DB_NAME "lms" `
  -ArchivePath "D:\Backups\mongodb\lms-20250101_013000.archive.gz" `
  -Drop
```
- Khôi phục về local (sandbox) để kiểm thử an toàn:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File ".\document_database\backup\restore.ps1" `
  -MONGO_URI "mongodb://localhost:27017" `
  -DB_NAME "lms_sandbox" `
  -Drop
```

### 10.5 Bảo mật thông tin đăng nhập (khuyến nghị)
- Tránh hard-code `USER:PASS` trong script/task. Tuỳ chọn:
  - Dùng biến môi trường chứa toàn bộ URI: `setx MONGO_ATLAS_URI "mongodb+srv://USER:PASS@CLUSTER.mongodb.net"`, rồi gọi `-MONGO_URI $env:MONGO_ATLAS_URI`.
  - Dùng Windows Credential Manager hoặc file cấu hình được ACL hạn chế quyền.
- Nếu mật khẩu có ký tự đặc biệt, cần URL-encode (xem bảng dưới).

### 10.6 Lỗi Atlas thường gặp và cách xử lý
- "Authentication failed" / "not authorized":
  - Sai user/password; user không có quyền `readWrite` trên DB `lms`.
- "IP not allowed" / "connection closed":
  - Chưa whitelist IP máy hiện tại trong Atlas → Network Access → Add IP Address.
- "getaddrinfo ENOTFOUND" / DNS SRV lỗi:
  - Mạng nội bộ chặn DNS SRV; thử mạng khác hoặc cấu hình DNS.
- Mật khẩu có ký tự đặc biệt (URL-encode):
  - Ví dụ: `@` → `%40`, `#` → `%23`, `:` → `%3A`, `/` → `%2F`, `?` → `%3F`, `&` → `%26`, `=` → `%3D`.
  - URI đúng mẫu: `mongodb+srv://USER:ENCODED_PASS@CLUSTER.mongodb.net`.
- Task báo 0x1 khi chạy Atlas:
  - Thường do PATH không có mongodump trong context của Task → dùng wrapper `.cmd` đã `set PATH` như trên hoặc thêm Tools vào PATH hệ thống.
