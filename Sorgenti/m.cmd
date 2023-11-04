@echo off
setlocal
pushd "%~dp0"
wsl -e bash -l -c "make" || exit /b 1
call ..\..\go.cmd
