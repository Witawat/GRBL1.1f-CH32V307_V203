@echo off
setlocal enabledelayedexpansion
title GRBL - Build

:: ============================================================
::  Select MCU Config — EDIT THIS ONE LINE TO SWITCH MCU
:: ============================================================
call "%~dp0mcu_config_CH32V307.bat"
::call "%~dp0mcu_config_CH32V203.bat"

:: ============================================================
set PROJECT_ROOT=%~dp0..
for %%I in ("%PROJECT_ROOT%") do set "PROJECT_ROOT=%%~fI"
set OBJ_DIR=%PROJECT_ROOT%\obj
set OUT_DIR=%PROJECT_ROOT%\output
set TOOLCHAIN_BASE=C:\MounRiver\MounRiver_Studio2\resources\app\resources\win32\components\WCH\Toolchain

if "%TOOLCHAIN_CHOICE%"=="2" (
    set TC_NAME=RISC-V Embedded GCC12
    set GCC_PREFIX=riscv-wch-elf-
) else (
    set TC_NAME=RISC-V Embedded GCC
    set GCC_PREFIX=riscv-none-embed-
)

set TC_BIN=%TOOLCHAIN_BASE%\%TC_NAME%\bin
set GCC="%TC_BIN%\%GCC_PREFIX%gcc.exe"
set OBJCOPY="%TC_BIN%\%GCC_PREFIX%objcopy.exe"
set SIZE="%TC_BIN%\%GCC_PREFIX%size.exe"

:: ---- Build flags ----
set CFLAGS=%ARCH% -msmall-data-limit=0 -msave-restore -Os -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -fno-common %EXTRA_CFLAGS% -Wunused -Wuninitialized -g %DEFINES%
set INCLUDES=-I"%PROJECT_ROOT%\grbl" -I"%PROJECT_ROOT%\%MCU_FOLDER%" -I"%PROJECT_ROOT%\%MCU_FOLDER%\sdk\Core" -I"%PROJECT_ROOT%\%MCU_FOLDER%\sdk\Debug" -I"%PROJECT_ROOT%\%MCU_FOLDER%\sdk\Peripheral\inc"
set INCLUDES_ASM=-I"%PROJECT_ROOT%\%MCU_FOLDER%\sdk\Startup"
set LDFLAGS=%ARCH% -T"%PROJECT_ROOT%\%MCU_FOLDER%\ld\Link.ld" -nostartfiles -Xlinker --gc-sections -Wl,-Map="%OUT_DIR%\%OUTPUT_NAME%.map" --specs=nano.specs --specs=nosys.specs -lm

echo.
echo =============================================================
echo   GRBL %MCU_NAME% - Build  [%GCC_PREFIX%gcc]
echo   Architecture: %ARCH%
echo =============================================================
echo.

:: Check compiler
if not exist "%TC_BIN%\%GCC_PREFIX%gcc.exe" (
    echo [ERROR] Compiler not found: %TC_BIN%\%GCC_PREFIX%gcc.exe
    echo.
    echo  Check TOOLCHAIN_CHOICE in mcu_config_%MCU_NAME%.bat
    goto :BUILD_FAIL
)
echo [OK] Compiler: %TC_BIN%\%GCC_PREFIX%gcc.exe
echo.

:: Create obj and output directories
if not exist "%OBJ_DIR%" mkdir "%OBJ_DIR%"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

:: Create empty response file (use forward slashes for GCC)
echo.> "%OBJ_DIR%\objects.rsp"
set "OBJ_FWD=%OBJ_DIR:\=/%"

set ERR=0

echo --- Compiling C files ---

:: ============================================================
::  SDK Core
:: ============================================================
call :CC "%PROJECT_ROOT%\%MCU_FOLDER%\sdk\Core\core_riscv.c"               "core_riscv.o"

:: ============================================================
::  SDK Debug
:: ============================================================
if exist "%PROJECT_ROOT%\%MCU_FOLDER%\sdk\Debug\debug.c" (
    call :CC "%PROJECT_ROOT%\%MCU_FOLDER%\sdk\Debug\debug.c"               "debug.o"
)

:: ============================================================
::  SDK Peripheral/src (WCH drivers)
:: ============================================================
for %%F in ("%PROJECT_ROOT%\%MCU_FOLDER%\sdk\Peripheral\src\*.c") do (
    call :CC "%%F" "%%~nF.o"
)

:: ============================================================
::  MCU: Application Layer
:: ============================================================
call :CC "%PROJECT_ROOT%\%MCU_FOLDER%\main.c"                              "main.o"

:: System clock init (system_ch32v30x.c or system_ch32v20x.c, etc.)
for %%F in ("%PROJECT_ROOT%\%MCU_FOLDER%\system_*.c") do (
    call :CC "%%F" "%%~nF.o"
)

:: Interrupt handlers
for %%F in ("%PROJECT_ROOT%\%MCU_FOLDER%\*_it.c") do (
    call :CC "%%F" "%%~nF.o"
)

:: USB device (optional)
if not "%USB_SOURCE%"=="" (
    if exist "%PROJECT_ROOT%\%MCU_FOLDER%\%USB_SOURCE%" (
        call :CC "%PROJECT_ROOT%\%MCU_FOLDER%\%USB_SOURCE%"                "usb_device.o"
    )
)

:: Camera overlay (optional)
if not "%OV_SOURCE%"=="" (
    if exist "%PROJECT_ROOT%\%MCU_FOLDER%\%OV_SOURCE%" (
        call :CC "%PROJECT_ROOT%\%MCU_FOLDER%\%OV_SOURCE%"                 "camera.o"
    )
)

:: ============================================================
::  GRBL Core (CNC motion engine)
:: ============================================================
for %%F in ("%PROJECT_ROOT%\grbl\*.c") do (
    call :CC "%%F" "%%~nF.o"
)

:: ============================================================
::  Assembly: Startup
:: ============================================================
if not "%STARTUP_ASM%"=="" (
    echo   [ASM] Startup\%STARTUP_ASM%
    %GCC% %CFLAGS% %INCLUDES_ASM% -c "%PROJECT_ROOT%\%MCU_FOLDER%\sdk\Startup\%STARTUP_ASM%" -o "%OBJ_DIR%\startup.o" 2>&1
    if errorlevel 1 (
        echo   [ERROR] Startup assembly failed
        set ERR=1
    ) else (
        echo "%OBJ_FWD%/startup.o">> "%OBJ_DIR%\objects.rsp"
    )
)

if %ERR%==1 goto :BUILD_FAIL

echo.
echo --- Linking ---
%GCC% @"%OBJ_DIR%\objects.rsp" %LDFLAGS% -o "%OUT_DIR%\%OUTPUT_NAME%.elf" 2>&1
if errorlevel 1 (
    echo [ERROR] Linking failed
    goto :BUILD_FAIL
)
echo [OK] output\%OUTPUT_NAME%.elf

echo.
echo --- Creating HEX ---
%OBJCOPY% -O ihex "%OUT_DIR%\%OUTPUT_NAME%.elf" "%OUT_DIR%\%OUTPUT_NAME%.hex" 2>&1
if errorlevel 1 (
    echo [WARNING] HEX creation failed
) else (
    echo [OK] output\%OUTPUT_NAME%.hex
)

echo.
echo --- Creating BIN ---
%OBJCOPY% -O binary "%OUT_DIR%\%OUTPUT_NAME%.elf" "%OUT_DIR%\%OUTPUT_NAME%.bin" 2>&1
if errorlevel 1 (
    echo [WARNING] BIN creation failed
) else (
    echo [OK] output\%OUTPUT_NAME%.bin
)

echo.
echo --- Firmware Size ---
%SIZE% --format=berkeley "%OUT_DIR%\%OUTPUT_NAME%.elf"

echo.
echo --- Memory Usage (%MCU_NAME%: Flash=%FLASH_TOTAL%  RAM=%RAM_TOTAL%) ---
%SIZE% --format=berkeley "%OUT_DIR%\%OUTPUT_NAME%.elf" > "%OBJ_DIR%\size.tmp"
for /f "usebackq skip=1 tokens=1,2,3" %%a in ("%OBJ_DIR%\size.tmp") do (
    set /a TEXT=%%a
    set /a DATA=%%b
    set /a BSS=%%c
    set /a FLASH_USED=%%a+%%b
    set /a RAM_USED=%%b+%%c
)
set /a FLASH_FREE=FLASH_TOTAL-FLASH_USED
set /a RAM_FREE=RAM_TOTAL-RAM_USED
set /a FLASH_PCT=FLASH_USED*100/FLASH_TOTAL
set /a RAM_PCT=RAM_USED*100/RAM_TOTAL
del "%OBJ_DIR%\size.tmp" 2>nul

echo.
echo   Flash:  %FLASH_USED% / %FLASH_TOTAL% bytes  (%FLASH_PCT%%%)  [Free: %FLASH_FREE% bytes]
echo   RAM:    %RAM_USED% / %RAM_TOTAL% bytes  (%RAM_PCT%%%)  [Free: %RAM_FREE% bytes]
echo.

if %FLASH_USED% GTR %FLASH_TOTAL% (
    echo [WARNING] Flash overflow! %FLASH_USED% ^> %FLASH_TOTAL%
)
if %RAM_USED% GTR %RAM_TOTAL% (
    echo [WARNING] RAM overflow! %RAM_USED% ^> %RAM_TOTAL%
)

echo.
echo =============================================================
echo   [OK] Build successful!
echo.
echo   Intermediate : obj\  (*.o)
echo   Final output : output\%OUTPUT_NAME%.elf
echo                  output\%OUTPUT_NAME%.hex
echo                  output\%OUTPUT_NAME%.bin
echo                  output\%OUTPUT_NAME%.map
echo =============================================================
echo.
goto :EOF


:CC
    echo   [C] %~nx1
    %GCC% %CFLAGS% %INCLUDES% -c %1 -o "%OBJ_DIR%\%~2" 2>&1
    if errorlevel 1 (
        echo   [ERROR] Compile failed: %~nx1
        set ERR=1
        exit /b 1
    )
    echo "%OBJ_FWD%/%~2">> "%OBJ_DIR%\objects.rsp"
    exit /b 0


:BUILD_FAIL
    echo.
    echo =============================================================
    echo   [ERROR] Build failed!
    echo =============================================================
    echo.
    exit /b 1
