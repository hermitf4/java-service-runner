@echo off
echo.
echo  ####  #####  ####  #####         ####  ###### #####  #    # #  ####  ######  #### 
echo #        #   #    # #    #       #      #      #    # #    # # #    # #      #     
echo  ####    #   #    # #    # #####  ####  #####  #    # #    # # #      #####   #### 
echo      #   #   #    # #####             # #      #####  #    # # #      #           #
echo #    #   #   #    # #            #    # #      #   #   #  #  # #    # #      #    #
echo  ####    #    ####  #             ####  ###### #    #   ##   #  ####  ######  #### 
echo.
echo  JavaServiceRunner - Stop script
echo.

setlocal enableextensions enabledelayedexpansion

REM === Determine root directory ===
set "ROOT_DIR=%~dp0.."
pushd "%ROOT_DIR%"

REM === Load configuration file ===
set CONFIG_FILE=bin\services-runner.cfg

if exist "%CONFIG_FILE%" (
    for /f "usebackq tokens=1,2 delims==" %%a in ("%CONFIG_FILE%") do (
        if not "%%a"=="" (
            echo %%a | findstr /b "#">nul
            if errorlevel 1 (
                set "%%a=%%b"
            )
        )
    )
) else (
	echo [WARN] Configuration file "%CONFIG_FILE%" not found. Using defaults.
)

set "SERVICES_DIR=%~1"
set "LOG_DIR=%~2"
set "TARGET_PID=%~3"

if not defined SERVICES_DIR if defined services.dir set "SERVICES_DIR=%services.dir%"
if not defined LOG_DIR if defined logs.dir set "LOG_DIR=%logs.dir%"

REM === RECOGNITION OF "PID-ONLY" FORMAT (1ST ARGUMENT IS NUMERIC, NO OTHERS) ===
if "%~2"=="" if not "%~1"=="" (
  set "onlyArg=%~1"
  set "NON_NUM="
  for /f "delims=0123456789" %%Z in ("%onlyArg%") do set "NON_NUM=%%Z"
  if not defined NON_NUM (
    set "TARGET_PID=!onlyArg!"
    set "SERVICES_DIR="
    set "LOG_DIR="
  ) 
)

if not defined SERVICES_DIR set "SERVICES_DIR=services"
if not defined LOG_DIR set "LOG_DIR=logs"

if not exist "%LOG_DIR%" (
  mkdir "%LOG_DIR%" >nul 2>&1
)

echo(
echo(==========================================================
echo( Stopping services via JavaServiceRunner
echo( Directory: "%SERVICES_DIR%"
echo( PID file located in: "%LOG_DIR%"
if defined TARGET_PID echo( Target PID: "%TARGET_PID%"
echo(==========================================================
echo(

REM === REM  PID-ONLY MODE (DO NOT TOUCH OTHER .PID FILES) ===
if defined TARGET_PID (
  dir /b /a:-d "%LOG_DIR%\*.pid" >nul 2>&1

  if errorlevel 1 (
	echo([ERROR] No .pid file found in "%LOG_DIR%".
    exit /b 1
  )

  set "MATCHED_PID_FILE="
  
  for /f "delims=" %%P in ('dir /b /a:-d "%LOG_DIR%\*.pid" 2^>nul') do (
    set "CAND_PID="
	
	for /f "usebackq tokens=* delims=" %%Q in ("%LOG_DIR%\%%P") do (
      if not defined CAND_PID set "CAND_PID=%%Q"
    )
	
	 if defined CAND_PID (
        set "CAND_PID=!CAND_PID: =!"

        for /f "delims=" %%R in ("!CAND_PID!") do set "CAND_PID=%%R"

        set "CAND_PID=!CAND_PID:~0,32766!"

        if "!CAND_PID!"=="!TARGET_PID!" (            
			set "MATCHED_PID_FILE=!LOG_DIR!\%%P"
        )
    )
  )

  if not defined MATCHED_PID_FILE (
    echo([ERROR] Target PID %TARGET_PID% not found in any .pid file under "%LOG_DIR%".
    echo(No file and no process have been touched.
    exit /b 1
  )

  call :kill_by_pid_file "!MATCHED_PID_FILE!" "!TARGET_PID!"
  echo(----------------------------------------------------------
  goto :end
)


REM === MASSIVE MODE (NO TARGET PID) ===
dir /b /a:-d "%SERVICES_DIR%\*.jar" >nul 2>&1

if errorlevel 1 (
  echo([ERROR] No JAR file found in the "%SERVICES_DIR%" folder.
  exit /b 1
)

for /f "delims=" %%J in ('dir /b /a:-d "%SERVICES_DIR%\*.jar" 2^>nul') do (
  set "SERVICENAME=%%~nJ"
  call :kill_by_service "%LOG_DIR%" "!SERVICENAME!"
  echo(----------------------------------------------------------
)
goto :end


:kill_by_pid_file
rem ---------------------------------------------------------
rem  Terminates ONLY the specified process, operating on ONE .pid file
rem    %~1 = full path to the PID file
rem    %~2 = expected PID (target)
rem ---------------------------------------------------------
setlocal enabledelayedexpansion 
set "PID_FILE=%~1"
set "EXPECTED=%~2"

if not exist "%PID_FILE%" (
  echo([INFO] The PID file no longer exists: "%PID_FILE%". No action taken.
  goto :exit_k1
)

set "PID="
for /f "usebackq tokens=* delims=" %%R in ("%PID_FILE%") do (
  if not defined PID set "PID=%%R"
)

if not defined PID (
  echo([WARN] The file "%PID_FILE%" is empty. No action taken.
  goto :exit_k1
)

set "PID=!PID: =!"

if not "!PID!"=="!EXPECTED!" (
  echo([WARN] The file "%PID_FILE%" does not contain the expected PID !EXPECTED!, it contains "!PID!". No action taken.
  goto :exit_k1
)


REM === CHECK PROCESS EXISTENCE) ===
set "FOUND="
for /f "skip=1 tokens=1,*" %%A in ('tasklist /FI "PID eq !PID!" /NH') do (
  if not "%%A"=="INFO:" set "FOUND=1"
)

if not defined FOUND (
  echo([INFO] No active process with PID !PID!. Cleaning up the PID file.
  
  del /f /q "%PID_FILE%" >nul 2>&1
  
  if errorlevel 1 (
    echo([WARN] Unable to delete "%PID_FILE%".
  ) else (
    echo([OK] PID file "%PID_FILE%" deleted.
  )
  
  goto :exit_k1
)

echo([INFO] Terminating process - PID !PID!

taskkill /PID !PID! /F >nul 2>&1

if errorlevel 1 (
  echo([ERROR] Unable to terminate PID !PID!. Check permissions or status.
) else (
  echo([OK] Process !PID! terminated successfully.
  
  del /f /q "%PID_FILE%" >nul 2>&1
  
  if errorlevel 1 (
    echo([WARN] Unable to delete "%PID_FILE%".
  ) else (
    echo([OK] PID file "%PID_FILE%" deleted.
  )
)

:exit_k1
endlocal
exit /b 0


:kill_by_service
rem ---------------------------------------------------------
rem  Terminates a service by name (massive mode)
rem    %~1 = LOG_DIR
rem    %~2 = SERVICENAME (basename of .jar)
rem ---------------------------------------------------------
setlocal enabledelayedexpansion
set "P_LOG=%~1"
set "SVC=%~2"
set "PID_FILE=%P_LOG%\%SVC%.pid"

if not exist "%PID_FILE%" (
  echo([INFO] No PID file for the service "!SVC!".
  goto :exit_k2
)

set "PID="
for /f "usebackq tokens=* delims=" %%R in ("%PID_FILE%") do (
  if not defined PID set "PID=%%R"
)
if not defined PID (
  echo([WARN] The file "%PID_FILE%" is empty. No action taken.
  goto :exit_k2
)
set "PID=!PID: =!"

set "FOUND="
for /f "skip=1 tokens=1,*" %%A in ('tasklist /FI "PID eq !PID!" /NH') do (
  if not "%%A"=="INFO:" set "FOUND=1"
)

if not defined FOUND (
  echo([INFO] No active process with PID !PID! for "!SVC!". Cleaning up the PID file.
  
  del /f /q "%PID_FILE%" >nul 2>&1
  
  if errorlevel 1 (
    echo([WARN] Unable to delete "%PID_FILE%".
  ) else (
    echo([OK] PID file "%PID_FILE%" deleted.
  )
  
  goto :exit_k2
)

echo([INFO] Terminazione processo - PID !PID! - servizio "!SVC!"
taskkill /PID !PID! /F >nul 2>&1
if errorlevel 1 (
  echo([ERROR] Unable to terminate PID !PID!.
) else (
  echo([OK] Process !PID! terminated successfully.
  
  del /f /q "%PID_FILE%" >nul 2>&1
  
  if errorlevel 1 (
    echo([WARN] Unable to delete "%PID_FILE%".
  ) else (
    echo([OK] PID file "%PID_FILE%" deleted.
  )
)

:exit_k2
endlocal
exit /b 0

:end
echo(
echo ==========================================================
echo  Stop sequence completed.
echo ==========================================================

popd
endlocal
pause