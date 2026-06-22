@echo off
cd /d D:\KotelAI\heating-system
timeout /t 30 /nobreak >nul
docker-compose up -d
exit