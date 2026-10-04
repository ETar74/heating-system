@echo off
cd /d "%~dp0"
timeout /t 30 /nobreak >nul
docker compose up -d
exit