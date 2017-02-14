:: Windows 7 SP1 require KB3125574
:: For roll-up of available windows 7 updates through April 2016
:: https://support.microsoft.com/en-us/kb/3125574

@echo off


@powershell -NoProfile -ExecutionPolicy Bypass -Command "((new-object net.webclient).DownloadFile('http://download.windowsupdate.com/d/msdownload/update/software/updt/2016/05/windows6.1-kb3125574-v4-x64_2dafb1d203c8964239af3048b5dd4b1264cd93b9.msu', 'C:\Windows\Temp\Windows6.1-KB3125574-x64.msu'))"

set hotfix="C:\Windows\Temp\Windows6.1-KB3125574-x64.msu"
if not exist %hotfix% goto :eof

:: get windows version
for /f "tokens=2 delims=[]" %%G in ('ver') do (set _version=%%G)
for /f "tokens=2,3,4 delims=. " %%G in ('echo %_version%') do (set _major=%%G& set _minor=%%H& set _build=%%I)

:: 6.1
if %_major% neq 6 goto :eof
if %_minor% lss 1 goto :eof

@echo on
start /wait wusa "%hotfix%" /quiet
