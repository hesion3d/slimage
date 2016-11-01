@echo off
set SLIMAGE_NAME=golang
set DOCKER_VERSION_SUPPORT=12
set FILE_NAME=%~nx0
set OUTPUT_DIR=%temp%/slimage

:slimage-main
setlocal enabledelayedexpansion
call :slimage-run-parseopts %*
if %ERRORLEVEL% equ 0 (
	call :slimage-run-checkenv
)
if %ERRORLEVEL% equ 0 (
	set DOCKER_ARGS=-v !GOPATH!:/gopath
	set DOCKER_ARGS=!DOCKER_ARGS! -v "%CD%":/dockerize
	set DOCKER_ARGS=!DOCKER_ARGS! -v "%OUTPUT_DIR%/bin":/gopath/bin
	set DOCKER_ARGS=!DOCKER_ARGS! -v "%OUTPUT_DIR%/out":/tmp/out
	set DOCKER_ARGS=!DOCKER_ARGS! !MOUTED_PATHS!
	set DOCKER_ARGS=!DOCKER_ARGS! -e DOCKER_IMAGE_LEVEL=!DOCKER_IMAGE_LEVEL!
    set DOCKER_ARGS=!DOCKER_ARGS! --env-file=!DOCKER_CONFIG_FILE!
	call :slimage-image-run !DOCKER_ARGS!
)
if ERRORLEVEL 0 (
	call :slimage-image-build
)
endlocal
goto :eof

:slimage-run-parseopts
set DOCKER_CONFIG_FILE=
set DOCKER_IMAGE_LEVEL=
set DOCKER_IMAGE_NAME=
set DOCKER_MOUNTED_PATHS=
if "%1" == "" (
	goto slimage-run-usage
) else (
	call :slimage-parseopts-loop %*
	if not exist !DOCKER_CONFIG_FILE! (
		if !ERRORLEVEL! equ 0 (
			echo.No config file or the specified config file not exist!
			set ERRORLEVEL=2
			goto :eof
		)
		for /f "delims=" %%i in ('echo !DOCKER_CONFIG_FILE!') do (
			set DOCKER_CONFIG_FILE=%%~fsi
		)
	)
	if "!DOCKER_IMAGE_NAME!" == "" (
		for /f "delims=" %%i in ('echo !DOCKER_CONFIG_FILE!') do (
			set DOCKER_IMAGE_NAME=%%~ni
		)
	)
	if "!DOCKER_IMAGE_LEVEL!" == "" (
		set DOCKER_IMAGE_LEVEL=basic
	)
	if not "!DOCKER_MOUNTED_PATHS!" == "" (
		set MOUTED_PATHS=
		for %%i in (!DOCKER_MOUNTED_PATHS!) do (
			set MOUTED_PATHS=-v %%i !MOUTED_PATHS!
		)
	)
)
set ERRORLEVEL=0
goto :eof

:slimage-parseopts-loop
if "%1" == "" (
	goto :eof
)
set left=%1
set left=%left:-=%
set left=%left:/=%
shift
if /i "%left%" == "f" (
	set DOCKER_CONFIG_FILE="%~f1"
) else if /i "%left%" == "l" (
	set DOCKER_IMAGE_LEVEL="%1"
) else if /i "%left%" == "n" (
	set DOCKER_IMAGE_NAME="%1"
) else if /i "%left%" == "v" (
	set DOCKER_MOUNTED_PATHS=!DOCKER_MOUNTED_PATHS! %1
) else if /i "%left%" == "h" (
	goto :slimage-run-help
)
set left=
goto :slimage-parseopts-loop

:slimage-run-checkenv
if not defined GOPATH (
	echo.Please specify GOPATH at first.
	set ERRORLEVEL=3
	goto :eof
)

for /f "delims=: tokens=2,3" %%i in ('docker version^|findstr /n /i "Version"') do (
	for /f "delims=. tokens=2" %%m in ('echo %%j') do (
		if %%m lss %DOCKER_VERSION_SUPPORT% (
			echo.Sorry, your docker version is not supported, please update at first.
			set ERRORLEVEL=3
		)
		goto :eof
	)
	goto :eof
)

:slimage-run-usage
echo.Usage: %FILE_NAME% [-f file][-l level][-n name][-v mounted files or dirs][-h]
set ERRORLEVEL=1
goto :eof

:slimage-run-help
echo.This script is used to run dockerize image and build go source automatically.
echo.-h Show this help.
echo.-f file The config file used for docker running
echo.-l level There are 4 levels to build, [min, basic, extra, net].
echo.   min: we only have the res file which defined in config file.
echo.   basic: we also have some basic filetools: ls, cat, echo, grep.
echo.   extra: extends basic set with some useful tools: bash, sh, dash, pwd, mkdir, chmod, chown, rm, sed, ln, cp, mv.
echo.   net: extends extra set with net tools: curl, ping, ss, ip.
echo.   if not set, will use basic, if you want more other tools, you should add in config file with RES_FILES
echo.-n name Docker image name which will build out. If not set, will be the name of config file.
echo.-v extra mounted files or dirs, used in copy dockerized files. format: -v %%USERPROFILE%%\Docuemtns:/root/doc -v d:/data:/data.
echo.When using in MINGW, our script and GOPATH should only in current user directory, which restricted by docker.
set ERRORLEVEL=1
goto :eof

:slimage-image-run
docker run --privileged %* --rm %SLIMAGE_NAME% bash -c "source /dockerize/dockerize.sh"
goto :eof

:slimage-image-build
echo Building...
docker build --rm -t %DOCKER_IMAGE_NAME% "%OUTPUT_DIR%/out"
goto :eof
