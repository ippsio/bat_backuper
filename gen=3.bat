@echo off
rem -----------------------------------------------------------------------------------
rem  Usage: gen=3.bat
rem   ファイル名の gen=n で指定した世代だけ、バックアップを取りますよ。
rem   バックアップ対象は、このbatファイルを置いてるフォルダ。
rem -----------------------------------------------------------------------------------

rem ---------------------------------------------------
rem 対象フォルダ(TARGET)の設定
set orgdir=%~dp0
cd %~dp0
FOR /F "DELIMS=" %%A IN ("%CD%") DO SET TARGET=%%~nxA
cd ..
rem ---------------------------------------------------
rem 世代(GENERATION)の設定
set GENERATION=%~n0
set GENERATION=%GENERATION:gen=%
FOR /F "DELIMS==" %%A IN ("%GENERATION%") DO SET GENERATION=%%~A
rem 入力値チェック
echo GENERATION=%GENERATION%
echo %GENERATION%| findstr /x /r "^[+-]*[0-9]*[\.]*[0-9]*$" 1>nul
if %ERRORLEVEL% equ 0 (set ISNUMERIC=1) else (set ISNUMERIC=0)
if %ISNUMERIC% neq 1 (
	echo; ＞世代は数字で[NG: %~0]
	cd %orgdir%
	timeout 5
	exit 1
)
echo; #############################################################
echo; ・%CD%\[%TARGET%] を[%GENERATION%]世代までバックアップします。
echo; #############################################################
rem #設定値確認
if ""%TARGET%""=="""" goto setting_error

rem #プロセスID取得
for /f %%i in ('powershell "foreach($p in (get-wmiobject win32_process -filter processid=$pid)){$ppid=$p.parentprocessid;}foreach($p in (get-wmiobject win32_process -filter processid=$ppid)){$p.parentprocessid;}"') do set PID=%%i
set tmp1=tmp1.%TARGET%.%PID%.txt
set tmp2=tmp2.%TARGET%.%PID%.txt
set prefix=bk_

SET WAIT_SEC=10
call :compare_diff %WAIT_SEC%
set /a do_compare=%ERRORLEVEL%
if %do_compare% EQU 1 (
  echo; ＞差分チェックします
  rem #BK1とSRCを比較。差分がなければ即時終了(:size_zero)
  %WINDIR%\system32\robocopy "%TARGET%" "%prefix%%TARGET%_1" /L /E /XO /Z /R:3 /FFT /TEE /TS /LOG:%tmp1%
  rem 日本語環境でも英語で出力される物もある。全部英語で統一してくれよ。
  FINDSTR /C:"Newer"       %tmp1% >> %tmp2%
  FINDSTR /C:"New Dir"     %tmp1% >> %tmp2%
  FINDSTR /C:"New File"    %tmp1% >> %tmp2%
  FINDSTR /C:"*EXTRA File" %tmp1% >> %tmp2%
  FINDSTR /C:"*EXTRA Dir"  %tmp1% >> %tmp2%
  FINDSTR /C:"より新しい"       %tmp1% >> %tmp2%
  FINDSTR /C:"新しいディレクトリ"     %tmp1% >> %tmp2%
  FINDSTR /C:"新しいファイル"    %tmp1% >> %tmp2%
  FOR %%F IN (%tmp2%) DO IF %%~zF EQU 0 GOTO size_zero
) else (
  echo; ＞差分チェック省略します
)

rem #バックアップとる（BK3->BK4, BK2->BK3, BK1->BK2）
setlocal enabledelayedexpansion
for /L %%i in (%GENERATION%, -1, 2) do (
	set /a iFROM=%%i-1
	set /a iTO=%%i
	set TO=%prefix%%TARGET%_!iTO!
	set FROM=%prefix%%TARGET%_!iFROM!

	IF EXIST !FROM! (
		IF EXIST !TO! (
			echo; ＞世代を進めます（route0 [!%iFROM!, !iTO!]）
			move /Y !TO! !TO!.del
			move /Y !FROM! !TO!
			IF ERRORLEVEL 0 (
				echo; ＞世代を進めました（route1 [!%iFROM!, !iTO!]）
				rmdir /S /Q !TO!.del
			) else (
				echo; ＞ROBOCOPY開始します（"!FROM!"→"!TO!"）
				%WINDIR%\system32\robocopy !FROM! !TO! /NP /COPY:DAT /DCOPY:T /R:3 /E /PURGE
				rmdir /S /Q !TO!.del
				echo; ＞世代を進めました（route2 [!%iFROM!, !iTO!]）
			)
		) else (
			move /Y !FROM! !TO!
			echo; ＞世代を進めました（route3 [!%iFROM!, !iTO!]）
		)
	)
)

rem #バックアップとる（SRC->BK1）
echo; ＞ROBOCOPY開始します（"%TARGET%"→"%prefix%%TARGET%_1"）
%WINDIR%\system32\robocopy "%TARGET%" "%prefix%%TARGET%_1" /NP /COPY:DAT /DCOPY:T /R:3 /E /PURGE
echo; ＞バックアップしました
endlocal
goto finish

:setting_error
echo; ＞SET TARGET=を設定して下さい。
goto finish

:size_zero
echo; ＞変更なしでした。バックアップ取んない。
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
if "%dt:~0,1%" == "0" set dt=%dt:~1% rem 01月~09月は、先頭0をチョップ
set /a dt_start=dt

echo;
echo;
echo;　強制的にバックアップ取りたいなら、何かキー押して。早く。
echo;　*********************************************************************
echo;　　・放っておくと差分バックアップ（差分チェックするから遅い）
echo;
echo;　　・なんか押すと差分関係なく強制的バックアップ（差分見ない分、速い）
echo;　***********************************************************************
timeout /t %1

set dt=%date:~5%%time:~0,8%
set dt=%dt:/=%
set dt=%dt::=%
set dt=%dt:.=%
if "%dt:~0,1%" == "0" set dt=%dt:~1% rem 01月~09月は、先頭0をチョップ
set /a dt_end=dt

set /a dt_diff=dt_end-dt_start
if %dt_diff% LSS %1 (
	exit /b 0
) else (
	exit /b 1
)
rem #######################################################################################

