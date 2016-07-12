@echo off
rem -----------------------------------------------------------------------------------
rem  Usage: gen3.bat
rem   �t�@�C������ genN �Ŏw�肵��N���ゾ���A�o�b�N�A�b�v�����܂���B
rem   �o�b�N�A�b�v�Ώۂ́A����bat�t�@�C����u���Ă�t�H���_�B
rem -----------------------------------------------------------------------------------

rem ---------------------------------------------------
rem �Ώۃt�H���_(TARGET)�̐ݒ�
set orgdir=%~dp0
cd %~dp0
FOR /F "DELIMS=" %%A IN ("%CD%") DO SET TARGET=%%~nxA
cd ..
rem ---------------------------------------------------
rem ����(GENERATION)�̐ݒ�
set GENERATION=%~n0
set GENERATION=%GENERATION:gen=%

FOR /F "DELIMS==" %%A IN ("%GENERATION%") DO SET GENERATION=%%~A
rem ���͒l�`�F�b�N
echo GENERATION=%GENERATION%
echo %GENERATION%| findstr /x /r "^[+-]*[0-9]*[\.]*[0-9]*$" 1>nul
if %ERRORLEVEL% equ 0 (set ISNUMERIC=1) else (set ISNUMERIC=0)
if %ISNUMERIC% neq 1 (
	echo; ������͐�����[NG: %~0]
	cd %orgdir%
	timeout 5
	exit 1
)

echo; #############################################################
echo; �E%CD%\[%TARGET%] ��[%GENERATION%]����܂Ńo�b�N�A�b�v���܂��B
echo; #############################################################
rem #�ݒ�l�m�F
if ""%TARGET%""=="""" goto setting_error

rem #�v���Z�XID�擾
for /f %%i in ('powershell "foreach($p in (get-wmiobject win32_process -filter processid=$pid)){$ppid=$p.parentprocessid;}foreach($p in (get-wmiobject win32_process -filter processid=$ppid)){$p.parentprocessid;}"') do set PID=%%i
set tmp1=tmp1.%TARGET%.%PID%.txt
set tmp2=tmp2.%TARGET%.%PID%.txt
set prefix=bk_

SET WAIT_SEC=10
call :compare_diff %WAIT_SEC%
set /a do_compare=%ERRORLEVEL%
if %do_compare% EQU 1 (
  echo; �������`�F�b�N���܂�
  rem #BK1��SRC���r�B�������Ȃ���Α����I��(:size_zero)
  %WINDIR%\system32\robocopy "%TARGET%" "%prefix%%TARGET%_1" /L /E /XO /Z /R:3 /FFT /TEE /TS /LOG:%tmp1%
  rem ���{����ł��p��ŏo�͂���镨������B�S���p��œ��ꂵ�Ă����B
  FINDSTR /C:"Newer"       %tmp1% >> %tmp2%
  FINDSTR /C:"New Dir"     %tmp1% >> %tmp2%
  FINDSTR /C:"New File"    %tmp1% >> %tmp2%
  FINDSTR /C:"*EXTRA File" %tmp1% >> %tmp2%
  FINDSTR /C:"*EXTRA Dir"  %tmp1% >> %tmp2%
  FINDSTR /C:"���V����"       %tmp1% >> %tmp2%
  FINDSTR /C:"�V�����f�B���N�g��"     %tmp1% >> %tmp2%
  FINDSTR /C:"�V�����t�@�C��"    %tmp1% >> %tmp2%
  FOR %%F IN (%tmp2%) DO IF %%~zF EQU 0 GOTO size_zero
) else (
  echo; �������`�F�b�N�ȗ����܂�
)

rem #�o�b�N�A�b�v�Ƃ�iBK3->BK4, BK2->BK3, BK1->BK2�j
setlocal enabledelayedexpansion
for /L %%i in (%GENERATION%, -1, 2) do (
	set /a iFROM=%%i-1
	set /a iTO=%%i
	set TO=%prefix%%TARGET%_!iTO!
	set FROM=%prefix%%TARGET%_!iFROM!

	IF EXIST !FROM! (
		IF EXIST !TO! (
			echo; �������i�߂܂��iroute0 [!%iFROM!, !iTO!]�j
			move /Y !TO! !TO!.del
			move /Y !FROM! !TO!
			IF ERRORLEVEL 0 (
				echo; �������i�߂܂����iroute1 [!%iFROM!, !iTO!]�j
				rmdir /S /Q !TO!.del
			) else (
				echo; ��ROBOCOPY�J�n���܂��i"!FROM!"��"!TO!"�j
				%WINDIR%\system32\robocopy !FROM! !TO! /NP /COPY:DAT /DCOPY:T /R:3 /E /PURGE
				rmdir /S /Q !TO!.del
				echo; �������i�߂܂����iroute2 [!%iFROM!, !iTO!]�j
			)
		) else (
			move /Y !FROM! !TO!
			echo; �������i�߂܂����iroute3 [!%iFROM!, !iTO!]�j
		)
	)
)

rem #�o�b�N�A�b�v�Ƃ�iSRC->BK1�j
echo; ��ROBOCOPY�J�n���܂��i"%TARGET%"��"%prefix%%TARGET%_1"�j
%WINDIR%\system32\robocopy "%TARGET%" "%prefix%%TARGET%_1" /NP /COPY:DAT /DCOPY:T /R:3 /E /PURGE
echo; ���o�b�N�A�b�v���܂���
endlocal
goto finish

:setting_error
echo; ��SET TARGET=��ݒ肵�ĉ������B
goto finish

:size_zero
echo; ���ύX�Ȃ��ł����B�o�b�N�A�b�v���Ȃ��B
goto finish

:finish
IF EXIST %tmp1% del %tmp1%
IF EXIST %tmp2% del %tmp2%

cd %orgdir%
timeout /t 5 /NOBREAK
exit

rem #######################################################################################
:compare_diff
set dt=%date:~5%%time:~0,8%
set dt=%dt:/=%
set dt=%dt::=%
set dt=%dt:.=%
if "%dt:~0,1%" == "0" set dt=%dt:~1% rem 01��~09���́A�擪0���`���b�v
set /a dt_start=dt

echo;
echo;
echo;�@�����I�Ƀo�b�N�A�b�v��肽���Ȃ�A�����L�[�����āB�����B
echo;�@*********************************************************************
echo;�@�@�E�����Ă����ƍ����o�b�N�A�b�v�i�����`�F�b�N���邩��x���j
echo;
echo;�@�@�E�Ȃ񂩉����ƍ����֌W�Ȃ������I�o�b�N�A�b�v�i�������Ȃ����A�����j
echo;�@***********************************************************************
timeout /t %1

set dt=%date:~5%%time:~0,8%
set dt=%dt:/=%
set dt=%dt::=%
set dt=%dt:.=%
if "%dt:~0,1%" == "0" set dt=%dt:~1% rem 01��~09���́A�擪0���`���b�v
set /a dt_end=dt

set /a dt_diff=dt_end-dt_start
if %dt_diff% LSS %1 (
	exit /b 0
) else (
	exit /b 1
)
rem #######################################################################################

