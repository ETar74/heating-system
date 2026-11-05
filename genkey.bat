@echo off
ssh-keygen -t ed25519 -f %USERPROFILE%\.ssh\id_ed25519 -C cline-deploy -N ""
