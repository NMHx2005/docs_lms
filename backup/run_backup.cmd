@echo off
set "PATH=C:\Program Files\MongoDB\Tools\100\bin;%PATH%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:\Self learning\CODE WEB\CodeThue\Learning_Management_System\document_database\backup\backup.ps1" -MONGO_URI "mongodb://localhost:27017" -DB_NAME "lms" -BACKUP_ROOT "D:\Backups\mongodb" -RETENTION_DAYS 7