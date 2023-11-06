@echo off
setlocal
pushd "%~dp0"
wsl -e bash -l -c "make" || exit /b 1
copy /y Breathless ..\..\hd\Breathless\
copy /y Breathless060 ..\..\hd\Breathless\
call ..\..\go.cmd
