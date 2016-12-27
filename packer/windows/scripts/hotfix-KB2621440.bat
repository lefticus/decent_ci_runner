:: Windows 7 SP1 require KB2621440 hotfix
:: https://support.microsoft.com/en-us/kb/2621440

@echo off




@powershell -NoProfile -ExecutionPolicy Bypass -Command "((new-object net.webclient).DownloadFile('https://download.microsoft.com/download/3/2/7/32799493-B549-4205-9C85-ED1498272377/Windows6.1-KB2621440-x86.msu', 'C:\Windows\Temp\Windows6.1-KB2621440-x64.msu'))"

set hotfix="C:\Windows\Temp\Windows6.1-KB2621440-x64.msu"
if not exist %hotfix% goto :eof

:: get windows version
for /f "tokens=2 delims=[]" %%G in ('ver') do (set _version=%%G)
for /f "tokens=2,3,4 delims=. " %%G in ('echo %_version%') do (set _major=%%G& set _minor=%%H& set _build=%%I)

:: 6.1
if %_major% neq 6 goto :eof
if %_minor% lss 1 goto :eof

@echo on
start /wait wusa "%hotfix%" /quiet
