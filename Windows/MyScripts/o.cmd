@echo off
REM o.cmd - open files/dirs with default app from cmd.exe
REM Usage: o [path]
if "%~1"=="" (
  powershell -NoProfile -Command "Start-Process -FilePath ."
) else (
  powershell -NoProfile -Command "Start-Process -FilePath '%*'"
)
