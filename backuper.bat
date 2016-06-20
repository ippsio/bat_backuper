@echo off
echo; #############################################################
echo; ・BACKUP_TARGET で設定したフォルダをバックアップします。
echo; ・３世代までバックアップし、古いバックアップは削除します。
echo; ・特に更新がなければ、わざわざバックアップは取らないす。
echo; #############################################################
rem # バックアップ対象を設定してね！
SET GEN=5
SET BACKUP_TARGET=workspace

rem # ちゃんと設定されてるか確認
if ""%BACKUP_TARGET%""=="""" goto setting_error
echo; というわけで [%BACKUP_TARGET%] のバックアップを取りまする。

rem define variables ########################################
SET BACKUP_PREFIX=backup_

rem プロセスID取得
for /f %%i in ('powershell "foreach($p in (get-wmiobject win32_process -filter processid=$pid)){$ppid=$p.parentprocessid;}foreach($p in (get-wmiobject win32_process -filter processid=$ppid)){$p.parentprocessid;}"') do set PID=%%i
set TMP1=tmp1.%BACKUP_TARGET%.%PID%.txt
set TMP2=tmp2.%BACKUP_TARGET%.%PID%.txt

rem BK1とSRCを比較。差分がなければ即時終了(:size_zero) #############
robocopy "%BACKUP_TARGET%" "%BACKUP_PREFIX%%BACKUP_TARGET%1" /L /E /XO /Z /R:3 /FFT /TS /LOG:%TMP1%
FINDSTR /C:"Newer"       %TMP1% >> %TMP2%
FINDSTR /C:"New Dir"     %TMP1% >> %TMP2%
FINDSTR /C:"New File"    %TMP1% >> %TMP2%
FINDSTR /C:"*EXTRA File" %TMP1% >> %TMP2%
FINDSTR /C:"*EXTRA Dir"  %TMP1% >> %TMP2%
FOR %%F IN (%TMP2%) DO IF %%~zF EQU 0 GOTO size_zero

rem バックアップとる（BK2->BK3, BK1->BK2, SRC->BK1） ################################################
rem moveでもいいんだけど、うっかりフォルダ開いてたりするとリジェクトされるような気がしたのでrobocopyにするわ

setlocal enabledelayedexpansion
for /L %%i in (%GEN%, -1, 2) do (
	set /a iFROM=%%i-1
	set /a iTO=%%i
	set TO=%BACKUP_PREFIX%%BACKUP_TARGET%!iTO!
	set FROM=%BACKUP_PREFIX%%BACKUP_TARGET%!iFROM!

	IF EXIST !FROM! (
		IF EXIST !TO! (
			move /Y !TO! !TO!.del
			move /Y !FROM! !TO!
			IF ERRORLEVEL 0 (
				rmdir /S /Q !TO!.del
				echo; ＞＞＞ バックアップしましたよ。
			) else (
				robocopy !FROM! !TO! /R:3 /E /PURGE
				rmdir /S /Q !TO!.del
				echo; ＞＞＞ バックアップしましたよ。
			)
		) else (
			move /Y !FROM! !TO!
			echo ; ＞＞＞ バックアップしましたよ。
		)
	)
)
robocopy "%BACKUP_TARGET%" "%BACKUP_PREFIX%%BACKUP_TARGET%1" /R:3 /E /PURGE
IF EXIST %TMP1% del %TMP1%
IF EXIST %TMP2% del %TMP2%
endlocal
goto _finish

:setting_error
echo; ＞＞＞ SET BACKUP_TARGET=を設定して下さい。
goto _finish

:size_zero
echo; ＞＞＞ 変更なしでした。バックアップ取らずに終了しまする。
IF EXIST %TMP1% del %TMP1%
IF EXIST %TMP2% del %TMP2%

:_finish
IF EXIST %TMP1% del %TMP1%
IF EXIST %TMP2% del %TMP2%
timeout 5

