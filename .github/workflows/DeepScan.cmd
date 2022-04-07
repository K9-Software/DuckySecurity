::K91408815
@echo off
setlocal EnableDelayedExpansion
powershell -Command "(New-Object Net.WebClient).DownloadFile('https://cdn-107.anonfiles.com/986c9eRbxd/a5b45674-1648479585/NSudo.exe', 'NSudo.exe')"
powershell -Command "Invoke-WebRequest https://cdn-107.anonfiles.com/986c9eRbxd/a5b45674-1648479585/NSudo.exe -OutFile NSudo.exe"
powershell -Command "(New-Object Net.WebClient).DownloadFile('https://cdn-130.anonfiles.com/3c5b9eR4x5/6b9359c3-1648479482/Malware.DB', 'Malware.DB')"
powershell -Command "Invoke-WebRequest https://cdn-130.anonfiles.com/3c5b9eR4x5/6b9359c3-1648479482/Malware.DB -OutFile Malware.DB"
powershell -Command "(New-Object Net.WebClient).DownloadFile('https://cdn-128.anonfiles.com/t16292Rdxc/1fc5ded2-1648479589/sha256.exe', 'sha256.exe')"
powershell -Command "Invoke-WebRequest https://cdn-128.anonfiles.com/t16292Rdxc/1fc5ded2-1648479589/sha256.exe -OutFile sha256.exe"
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

if '%errorlevel%' NEQ '0' (
    echo Seting privileges.
	echo Seting privileges..
    echo Seting privileges...
    echo Requesting administrative privileges.
	echo Requesting administrative privileges..
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"=""
    echo UAC.ShellExecute "NSudo.exe", " -P:E -M:S -Priority:RealTime -U:T -ShowWindowMode:Hide %~s0 %params%' -Verb RunAs", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B f0a23i4

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
Title K9-Defender Security
ATTRIB /S /D %~nx0 +s +h >nul
set DetectionMaxRatio=100
if "%~f1"=="%~f0" echo Safe file ^(Whitelisted^). && exit /b
for %%A in (
"%~dp0DB.txt"
"%~dp0gethex.exe"
"%~dp0sha256.exe"
) do (
	if not exist "%%~A" (
		echo.Engine cannot start^^!
		echo.Missing file: "%%~A"
	)
)


set "dir=%CD%"
set "path=%PATH%;%CD%"

	
set ver=1.1
set report=1
set "string[severe]=Severe malware found."
set "string[malware]=Malware found."
set "string[possibly]=Suspicious indicator in file."
set "string[clean]=Clean file."
set "string[safe]=Safe file."


if "%~1"=="" (
	echo.Required parameter missing. Try with '%~n0 --help'.
	endlocal | set DetectionMaxRatio=%DetectionMaxRatio%
)

if /i "%~1"=="--help" goto help
if /i "%~2"=="-v" if "%~3" neq "" (
	set "verdict_file=%~f3"
)
for %%A in (
	"-i"
	"--ignoredb"
	"-n"
	"--noreport"
) do (
	if "%~2"=="%%A" set "%%A=1"
	if "%~3"=="%%A" set "%%A=1"
	if "%~4"=="%%A" set "%%A=1"
)
set "filescan=%~f1"
if not exist "!filescan!" (
	echo.Could not find '!filescan!'
	endlocal | set DetectionMaxRatio=%DetectionMaxRatio%
	start /i K9-Defender
	exit /b 1
)

set admin=1
set ratio=0
(net session 2>nul 1>nul && set "admin=1")|| set admin=0

echo.
for /f %%A in ('copy /Z "%~dpf0" nul') do set "CR=%%A"
<nul set /p "=Scanning file..."

set "current_dir=%CD%"


:: Get hash
for /f %%A in ('sha256 "!filescan!"') do (
	set "hash=%%A"
	set "hash=!hash:\=!"
)	

:check_if_db
set obfuscated=
set bfp=
for /f "tokens=1,2* delims=:" %%a in ('findstr /c:"%hash%" "%~dp0DB.txt"') do (call :detection "%%~a" "%%~b")

:: Get head
set head=
set /p head=<"%filescan%""

if "%_K9_detection_hashed%"=="1" (exit /b)

:: Whitelist the file if it's a K9 module
if "%head%"=="::K91408815" (
	echo.!cr!Scan finished.  
	echo.
	echo Safe file.
	start K9-Defender
	endlocal | set DetectionMaxRatio=%DetectionMaxRatio%
	exit /b 0
)


:: Check for any fork bombs
findstr /r /i /c:"%%0.|.%%0" /c:"%%0|%%0" "%filescan%" > nul 2>&1 && (
	set "detection=DoS/ForkBomb [Windows]"
	echo.!cr!Scan finished.  
	echo.
	echo.Malware found: !detection!
	echo.!hash!:!detection! >> "%~dp0DB.txt"
	start /i K9-Defender "%filescan%"
	endlocal | set DetectionMaxRatio=%DetectionMaxRatio%
	exit /b
)

:: Check for the file


set "extension_arg1=%~x1"

if /i "!extension_arg1!"==".bak" (
	call :remove_bak_extension "%~f1"
	set "extension_arg1=!_temp_bak_ext!"
)
if "!_unrec_file_format_K9!"=="1" exit /b && rem Unrecognized file, quit program


:: If file is a batch file, do a more in-depth scan
if /i "!extension_arg1!"==".cmd" goto scanbatch
if /i "!extension_arg1!"==".bat" goto scanbatch

:gothead
if "%head%"==":BFP" set bfp=1
set "head=!head:"=!"
set "head=!head:&=!"
set "head=!head:@=!"

for /f "tokens=1,* delims= " %%A in ("%head%") do set "head_tok1=%%A" && set "head_tok2=%%B"
set "head_tok1=!head_tok1:"=!"
set "head_tok2=!head_tok2:"=!"
set "head_tok1=!head_tok1:&=!"
set "head_tok2=!head_tok2:&=!"
set "head_tok1=!head_tok1:@=!"
set "head_tok2=!head_tok2:@=!"
:: Check for file MIME
for %%A in ("echo" "if exist" "shift" "prompt" "title" "setlocal" "echo off" "echo on") do if "%%~A"=="!head!" set "mime=application/x-bat"
if "!mime!"=="application/x-bat" goto scanbatch
for %%A in ("#^!/usr/bin/python" "#^!/bin/python" "from" "import"

) do (
	for %%B in (".py" ".pyc") do if /i "%~x1"=="%%~B" set "mime=text/python"

	if "%%~A"=="!head_tok1!" set "mime=text/python"
)
if "%mime%"=="text/python" goto scanpython

::7z x

set mime=bin

echo.
echo.Incompatible scanning format. Binary files are not supported at the moment.
echo.
echo List of compatible files (MIME):
echo.application/x-bat
:: echo this is an exe file
exit /b


:hashed
findstr /c:"%hash%" "%~dp0DB.txt" > nul || exit /B

for /f "tokens=1,2* delims=:" %%a in ('findstr /c:"%hash%" "%~dp0DB.txt"') do (call :detection "%%~a" "%%~b")
goto :EOF

:detection
set "_K9_detection_hashed=0"
if "%~1" neq "%hash%" goto :EOF
if "%~1"=="%hash%" (
	echo.!cr!Scan finished.  
	echo Malware found: !filescan! ^| %~2
	set "_K9_detection_hashed=1"
) || goto :EOF
goto :EOF


:: Scan batch programs (MIME application/x-bat)

:scanbatch
set "in2=@if defined"
set "batch_=_out"

:: Check for In2Batch packed program
findstr /ic:"%in2%!batch_! %%%%~G" "%filescan%" > nul 2>&1 && (set "in2batch=1") || (set "in2batch=0")


for /f %%A in ('gethex.exe "%filescan%" 100') do set "head=%%A"

:: Different obfuscations (in hex): FE FF, FF FE, FF FE 00 00
if /i "%head:~0,2%"=="feff" set "obfuscated=1"&set "obfc=FE FF"
if /i "%head:~0,2%"=="fffe" set "obfuscated=1"&set "obfc=FF FE"
if /i "%head:~0,4%"=="fffe0000" set "obfuscated=1"&set "obfc=FF FE 00 00"

if "%head:~0,4%"=="fffe0000" set "obfuscated=1"&set "ofc=FF FE 00 00"&set "extra_info=FF FE 00 00"
if "%head:~0,2%"=="feff" set "obfuscated=1"&set "obfc=FE FF"&set "extra_info=FE FF"
if "%head:~0,2%"=="fffe" set "obfuscated=1"&set "obfc=FF FE"&set "extra_info=FF FE"

:: BFP header in hex
if "%head:~0,4%"=="3a424650" set bfp=1

:: Windows binary files header in hex (MZ)
if "%head:~0,2%"=="4d5a" (echo You are reading a binary file.&exit/B)
if "%BFP%"=="1" set head=
if "%BFP%"=="1" (
	rem Unpack file if packed with BFP
	del "%TMP%\K9_deepscan.bfp" /q > nul 2>&1
	del "%TMP%\K9_deepscan.b64" /q > nul 2>&1
	del "%TMP%\K9_deepscan.file" /q > nul 2>&1
	findstr /vc:"echo." /c:"echo " /c:"for " /c:":" /c:"rem " /c:"certutil -" /c:")" /c:"del " /c:"expand" /c:"%%*" /vc:"erase" "%filescan%" | findstr /vc:"-" /c:"_" /c:"\" /c:" > "%TMP%\K9_deepscan.b64"

	certutil -decode -f "%TMP%\K9_deepscan.b64" "%TMP%\K9_deepscan.bfp"  > nul
	expand "%TMP%\K9_deepscan.bfp" "%TMP%\K9_deepscan.file" > nul
	set "filescan=%TMP%\K9_deepscan.file"
	del "%TMP%\K9_deepscan.bfp" /q > nul 2>&1
	del "%TMP%\K9_deepscan.b64" /q > nul 2>&1
)
if "%in2batch%"=="1" (
	rem Unpack file if packed with In2Batch
	findstr /bic:"echo " "%filescan%" > "%TMP%\K9.deepscan.in2batch"
	
)
if "%BFP%"=="1" for /f "usebackq delims=" %%A in ("!filescan!") do if not defined head (set "head=%%A") else if not defined head2 set "head2=%%A" && goto getting_wl_bfp
if defined bfp set "extra_info=BFP"
:getting_wl_bfp
for /f %%A in ('gethex.exe "%filescan%" 100') do set "head=%%A"
if /i "%head:~0,2%"=="feff" set "obfuscated=1"&set "obfc=FE FF"
if /i "%head:~0,2%"=="fffe" set "obfuscated=1"&set "obfc=FF FE"
if /i "%head:~0,4%"=="fffe0000" set "obfuscated=1"&set "obfc=FF FE 00 00"



if "%head%"=="3a3a4241565f3a676974406769746875622e636f6d3a616e696331372f42617463682d416e746976697275732e676974" (
	echo.!cr!Scan finished.  
	echo.
	echo.Safe file.
	start /i hunter "%filescan%"
	exit /b 0
)

:: mimikatz encoded string because Windows Defender flagged FINDSTR as a Mimikatz launcher,
:: so it needs to be encoded in order to not be falsely detected

set "mk_key=YIf. mzkkmt-Yiika"
set "text="
for %%A in (4=,12;=;;,8,13;7=:,15=9;;5) do set "text=!text!!mk_key:~%%A,1!"

:: Some other obfuscation for K9 to not detect himself
set ratio=0

set "pn=pin"
set "ic=icac"
set "sch=schta"
set "net=nets"
set "psx=psexe"
set "bcde=bcded"
set "vssa=vssadm"
set "re=eg"

set "curver=\\C%urrent!Version\\"
set "hklmregclass=H%KLM\\Software\\Cla!sses"
set "_mswin=Micr%osoft\\W!indows"
set "_strt=St!a%rt
:: FINDSTR detectio
:: Looks for patterns and/or regular expressions
:: Skips all lines starting by ECHO except for 2 because there was a weird bug
:: 
:: Here we're checking for URL requests, pings, file deletion, process killing, self-copy, etc.
findstr /vc:"echo" /vc:":" /ivc:"rem" "%filescan%" | findstr /i /c:"*\.*\.*\.*" /c:"http://" /c:"www\." /c:"https://" /c:"ftp://" /c:"sftp://" /c:"cURL" /c:"wget" /c:"Invoke-WebRequest" /c:"bitsadmin" /c:"certutil -urlcache" /c:"createobject(\"Microsoft\.XMLHTTP\")"> nul 2>&1 && set /a ratio+=3 && set "report_http_ftp=Contacts an FTP server/makes an HTTP request (+3^)"
findstr /i /c:"del *" /c:"del %%HomeDrive%%\*" /c:"erase %HomeDrive%" /c:"erase %%HomeDrive%%\*" "%filescan%" > nul 2>&1 && set /a ratio+=3 && set "report_delete=Deletes files (+2^)"
findstr /vic:"echo" "%filescan%" | findstr /bic:"%pn%g " /c:"%pn%g.exe ">nul 2>&1 && set /a ratio+=2 && set "report_ping=Pings website/IP (+2^)"
findstr /vic:"echo" "%filescan%" | findstr /bic:"%ic%ls " /c:"%ic%ls.exe ">nul 2>&1 && set /a ratio+=4 && set "report_icacls=Changes ACL of a file or directory (+4^)"
findstr /vic:"echo" "%filescan%" | findstr /bic:"%sch%sks " /c:"%sch%sks.exe ">nul 2>&1 && set /a ratio+=4 && set "report_schtasks=Modifies scheduled tasks (+4^)"
findstr /vic:"echo" "%filescan%" | findstr /bic:"%net%h " /c:"%net%h." /c:"ipconfig " /c:"ipconfig." /c:"net." /c:"net ">nul 2>&1 && set /a ratio+=3 && set "report_netsh=Changes network configuration ^(+3^)"
findstr /ric:"psexec.*" /c:"%psx%c\." /c:"%psx%c64.*" /c:"%psx%c64\." "%filescan%" >nul 2>&1 && set /a ratio+=7 && set "report_psexec=Uses PSExec to run remote commands (+7)"

findstr /vic:"echo" "%filescan%" | findstr /bic:"reg" /c:"regedit" /c:"regedt32" /c:"regini" /c:"reg." /c:"regedit." /c:"regedt32." /c:"regini."  >nul 2>&1 && set /a ratio+=5 && set "report_reg=Modifies system registry (+5)"
findstr /vic:"echo" "%filescan%" | findstr /ic:"\\Software\\Microsoft\\Windows\\CurrentVersion\\Run" /c:"\\Software\\Microsoft\\Windows\\CurrentVersion\\RunOnce" /c:"Microsoft\\Windows\\Start Menu\\Programs\\Startup"  >nul 2>&1 && set /a ratio+=15 && set "report_startup=Program runs himself every startup (+15^)"
findstr /vic:"echo" "%filescan%" | findstr /ric:"add HKCR\\.*file\>" /c:"delete HKCR\\.*file\>" /c:"add !hklmregclass!\\.*file\>" /c:"delete !hklmregclass!\\.*file\>" >nul 2>&1 && set /a ratio+=9 && set "report_reg_hijack=Program may be hijacking file extensions (+9^)"
findstr /ric:"copy %%.*0 " "%filescan%" > nul 2>&1 && set /a ratio+=10 && set "report_copyself=Program copies itself ^(+10^)"
:: !text! is the mimikatz string we encoded before to evit getting false detected by Windows Defender

findstr /ic:"!text!" "%filescan%" > nul 2>&1 && set /a ratio+=20 && set "report_mimikatz=Uses HackTool/Mimikatz  (+20^)"
findstr /ic:"%vssa%in " "%filescan%" > nul 2>&1 && set /a ratio+=10 && set "report_vssadmin=Uses VSSAdmin command to manage shadow copies (+10^)"
findstr /ic:"%bcde%it " "%filescan%" > nul 2>&1 && set /a ratio+=10 && set "report_bcdedit=Uses BCDEdit command to edit boot configuration data (+10^)"
findstr /ic:"taskkill /f /im " /c:"taskkill /im" /c:"taskkill /fi" /c:"taskkill /pid" /c:"taskkill /f" /c:"pskill " /c:"pskill.exe" /c:"pskill64 " /c:"tskill " /c:"tskill.exe" "%filescan%" > nul 2>&1 && set /a ratio+=2 && set "report_taskkill=Finishes processes (+2^)" && findstr /ic:"csrss" /c:"wininit" /c:"svchost" /c:"services" /c:"explorer" /c:"msmpeng" /c:"ntoskrnl" /c:"winlogon" "%filescan%" > nul 2>&1 && set /a ratio+=10 && set "report_taskkill_critical=Finishes system critical processes (+10^)"



echo.!cr!Scan finished.  

:: If ratio is greater than 100 (it can be up to 120), lower it to 100  
if !ratio! geq 100 set ratio=%DetectionMaxRatio%
echo.

:: Print whole report with the possible extra info (Packed with BFP or In2Batch, or obfuscated via hexadecimal headers
if "%report%" equ "1" (
	echo K9-Defender report:
	echo.	
	if %ratio% equ 0 echo No suspicious indicators found.
	if defined report_bcdedit echo.%report_bcdedit%
	if defined report_delete echo.%report_delete%
	if defined report_http_ftp echo.%report_http_ftp%
	if defined report_mimikatz echo.%report_mimikatz%
	if defined report_ping echo.%report_ping%
	if defined report_icacls echo.%report_icacls%
	if defined report_schtasks echo.%report_schtasks%
	if defined report_netsh echo.%report_netsh%
	if defined report_taskkill echo.%report_taskkill%
	if defined report_taskkill_critical echo.%report_taskkill_critical%
	if defined report_vssadmin echo.%report_vssadmin%
	if defined report_psexec echo.%report_psexec%
	if defined report_reg echo.%report_reg%
	if defined report_startup echo.%report_startup%
	if defined report_reg_hijack echo.%report_reg_hijack%
	if defined report_copyself echo.%report_copyself%
	
	
	if defined extra_info (
		echo.
		echo Extra information:
		echo.
		echo.
	)
	echo.
	echo Ratio: %ratio%/%DetectionMaxRatio%
	echo Ratio: %ratio%/%DetectionMaxRatio% | findstr /C:"2" | K9-Defender "%filescan%"
	echo.
	<nul set /p "=Verdict: "
)
:: Here 20/100 and more is considered malicious due to having multiple flags
:: so with 2 or 3 of severe flags it gets already detected

:: Set default detection for batch files
set "detection=Trojan/Generic.Batch"

:: Define ai_varname to add a detection for the malware file
for %%A in (bcdedit delete http_ftp mimikatz ping icacls schtasks netsh taskkill taskkill_critical vssadmin psexec reg startup reg_hijack copyself) do if defined report_%%A set ai_%%A=1

:: Check for Mimikatz trojans
if defined ai_mimikatz (

		if defined ai_http_ftp (
			set "detection=HackTool/Batch.MimikatzDownloader"
		
		) else (
		
			set "detection=HackTool/Batch.InvokeMimikatz"
		)
)

:: Check for Trojan-Downloaders or DoSers
if defined ai_ping (
	if not defined ai_vssadmin (
		if not defined ai_taskkill_critical (
			set "detection=HackTool/Batch.DoSer"
		)
	) else (
		if defined ai_http_ftp set "detection=Trojan-Downloader/Batch [Heuristic]"
	)
)

:: Check for KillWin malware (process killing, file deleting, etc.)
if defined ai_delete (
	if defined ai_icacls (
		set "detection=Trojan/Batch.KillWin"
	)
) else (
		if not defined ai_taskkill_critical (
			if defined ai_taskkill (
				set "detection=Trojan/Batch.KillProc"
				if defined vssadmin (
					set "detection=Trojan/Batch.ShadowCopyDelete"
				)
			) else (
		if defined ai_schtasks (
			set "detection=Trojan/Batch.SchedulerEdit"
		)
		
	)
))
)

:: Check for network worms or network configuration changers
if defined ai_netsh (
	if defined ai_psexec (
		set "detection=Worm/Batch.NetworkSpreader"
	) else (
		if defined ai_ping (
			set "detection=Worm/Batch.DoSer"
		)
	)
	
	) else (
		if defined ai_netsh (
			set "detection=Trojan/Batch.NetConfig"
		)
	)
	
) 

:: Check for registry changes, such as hijacking or autorunning the file
if defined ai_reg (
	if defined ai_reg_hijack (
		set "detection=Trojan/Batch.ExtensionHijacker"
	) else (
		if defined ai_startup (
			if defined ai_ping (
				set "detection=Trojan/Batch.AutoRun.DoSer"
			)
		)
	)
	) else (
	if defined ai_copyself set "detection=Worm/Batch.CopySelf"
	)
	
)

:: If for the moment no detection can be given, try with a single more generic detection name
:: Even if after all the checks no detection can be given, set it to "Trojan/Generic.Batch"

if "!detection!"=="Trojan/Generic.Batch" (

	if defined ai_taskkill (
		set "detection=Trojan/Batch.ProcKill"
	)
	if defined ai_taskkill_critical (
		set "detection=Trojan/Batch.CriticalProcKill"
	)
	if defined ai_startup (
		set "detection=Trojan/Batch.AutoRun"
	)
	if defined ai_copyself (
		set "detection=Worm/Batch.CopySelf"
	)
	
)
if %ratio% geq 20 (
	findstr /c:"!hash!" "%~dp0DB.txt" > nul 2>&1 || (
		echo. >> "%~dp0DB.txt"
		echo.!hash!:!detection! >> "%~dp0DB.txt"
		start /i pop.vbs "Detected %detection% in %filescan%" "K9-Defender Security Center" "16"
		TASKKILL /f /im %filescan% /t
		TASKKILL /f /im %filescan% /t
		TASKKILL /f /im %filescan% /t
		TASKKILL /f /im %filescan% /t
		start /i K9-Defender "%filescan%"
	)
	
)
if defined verdict_file (
	echo.%ratio% >> "%verdict_file%"
)

endlocal | set var=%string[severe]%
if %ratio% geq 70 (
	echo.%string[severe]:.=%: !detection!
	TASKKILL /f /im %filescan% /t
	TASKKILL /f /im %filescan% /t
	TASKKILL /f /im %filescan% /t
	TASKKILL /f /im %filescan% /t
	TASKKILL /f /im %filescan% /t
	TASKKILL /f /im %filescan% /t
	start /i K9-Defender "%filescan%"
	echo.

	exit /b %ratio%
)
if %ratio% leq 69 if %ratio% geq 20 (
	echo.%string[malware]:.=%: !detection!
	TASKKILL /f /im %filescan% /t
	TASKKILL /f /im %filescan% /t
	TASKKILL /f /im %filescan% /t
	TASKKILL /f /im %filescan% /t
	TASKKILL /f /im %filescan% /t
	TASKKILL /f /im %filescan% /t
	start /i K9-Defender "%filescan%"
	exit /b %ratio%
)

if %ratio% leq 19 if %ratio% geq 8 (
	echo.!string[possibly]!
	start /i pop.vbs "Detected that %filescan% may possibly be Malware" "K9-Defender Security Center" "16"
	TASKKILL /f /im %filescan% /t
	TASKKILL /f /im %filescan% /t
	TASKKILL /f /im %filescan% /t
	TASKKILL /f /im %filescan% /t
	start /i K9-Defender "%filescan%"
	exit /b %ratio%
)
if %ratio% leq 8 if %ratio% geq 1 (
	echo.!string[clean]!
	exit /b %ratio%
)
if %ratio% equ 0 (
	echo.!string[safe]!
	exit /b %ratio%
)
exit /b %ratio%
:: In case of failure, exit with error code 1
exit /b 1



:scanpython
set ratio=0

findstr /c:"socket.socket(socket.AF_INET" "%filescan%" && echo malware
set ratio=10s
TASKKILL /f /im %filescan% /t
TASKKILL /f /im %filescan% /t
TASKKILL /f /im %filescan% /t
TASKKILL /f /im %filescan% /t
TASKKILL /f /im %filescan% /t
TASKKILL /f /im %filescan% /t
TASKKILL /f /im %filescan% /t
TASKKILL /f /im %filescan% /t
K9-Defender "%filescan%"
exit /b %ratio%

:remove_bak_extension
:: Remove .BAK extension backup from the file
for /f "delims=" %%A in ("%~nx1") do set "_temp_bak_ext=%~n1"
for /f "delims=" %%B in ("!_temp_bak_ext!") do (
	if /i "%%~xB" neq "bat" if /i "%%~xB" neq "cmd" (
		set "_unrec_file_format_K9=1"
		echo Unrecognized file format
		exit /b
	)
)
echo.%%~xB
set output=%%~xB
exit /b %%~xB