@echo off
echo.
echo  #####                                   #####                                      
echo #     # #####   ##   #####  #####       #     # ###### #####  #    # #  ####  ######
echo #         #    #  #  #    #   #         #       #      #    # #    # # #    # #     
echo  #####    #   #    # #    #   #   #####  #####  #####  #    # #    # # #      ##### 
echo       #   #   ###### #####    #               # #      #####  #    # # #      #     
echo #     #   #   #    # #   #    #         #     # #      #   #   #  #  # #    # #     
echo  #####    #   #    # #    #   #          #####  ###### #    #   ##   #  ####  ######
echo.
echo  JavaServiceRunner - Start script
echo.

setlocal enabledelayedexpansion

REM === Determine project root directory (script may run from /bin) ===
set "ROOT_DIR=%~dp0.."
pushd "%ROOT_DIR%"

set CONFIG_FILE=bin\services-runner.cfg

if not exist "%CONFIG_FILE%" (
    echo ERRORE: File di configurazione non trovato: %CONFIG_FILE%
    exit /b 1
)

for /f "usebackq tokens=1,2 delims==" %%a in ("%CONFIG_FILE%") do (
    rem Ignora commenti e righe vuote
    if not "%%a"=="" (
        echo %%a | findstr /b "#">nul
        if errorlevel 1 (
            set "%%a=%%b"
        )
    )
)

if not exist "%logs.dir%" (
    mkdir "%logs.dir%"
)

if not exist "%services.dir%" (
    echo [ERRORE] Directory dei servizi "%services.dir%" non trovata.
    exit /b 1
)

REM === LIST .JAR FILES ===
echo.
echo =========================================================================
echo  Starting Java services via JavaServiceRunner
echo  Services directory : "%services.dir%"
echo  Logs / PID directory : "%logs.dir%"
echo =========================================================================
echo.
echo Detected JAR files:

set "foundJar=false"
for %%F in (%services.dir%\*.jar) do (
    echo   %%F
    set "foundJar=true"
)

echo.

if "%foundJar%"=="false" (
	echo [ERROR] Configuration file not found: "%services.dir%"
    exit /b 1
)

REM === STARTING SERVICES ===
for %%F in (%services.dir%\*.jar) do (
    set "JARFILE=%%~nxF"
    set "SERVICENAME=!JARFILE:.jar=!"
    set "PID_PATH=%logs.dir%\!SERVICENAME!.pid"
    set "alreadyStarted="
    set "PID_VALUE="

    if exist "!PID_PATH!" (
        for /f "usebackq tokens=* delims=" %%P in ("!PID_PATH!") do (
            set "PID_VALUE=%%P"
        )
        if defined PID_VALUE (
            for /f "tokens=1,2,*" %%A in ('tasklist /FI "PID eq !PID_VALUE!" /NH') do (
                if /I "%%A"=="java.exe" (
					echo [INFO] !SERVICENAME! is already running with PID !PID_VALUE!. Skipped.
                    set "alreadyStarted=true"
                )
            )
        )
    )

    if not defined alreadyStarted (
		echo [%date% %time%] Starting !SERVICENAME!...

        start "" /B cmd /c ^
        "java -jar ""%services.dir%\!JARFILE!"" --spring.pid.file=""!PID_PATH!"" > ""%logs.dir%\!SERVICENAME!.out"" 2>&1"

		echo [OK] Start requested for !SERVICENAME!.
    )
    
	echo ----------------------------------------------------------
)

echo.

timeout /t 10 >nul

echo ===================== PID status after startup ============================
for %%F in (%services.dir%\*.jar) do (
    set "JARFILE=%%~nxF"
    set "SERVICENAME=!JARFILE:.jar=!"
    set "PID_PATH=%logs.dir%\!SERVICENAME!.pid"
    if exist "!PID_PATH!" (
        for /f "usebackq tokens=* delims=" %%P in ("!PID_PATH!") do (
			echo [OK] !SERVICENAME! started with PID %%P
        )
    ) else (
		echo [WARN] !SERVICENAME! - PID file not found
    )
)
echo =========================================================================
echo.
echo.
echo =========================================================================
echo  Operation completed.
echo  - All non-running services have been started.
echo  - Services already running were left untouched.
echo =========================================================================
echo.

popd
endlocal
pause
