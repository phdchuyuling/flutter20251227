@echo off
chcp 65001 >nul
title ♟️ Reversi Web Game Launcher

echo ===============================
echo  [1] 切換到此批次檔所在資料夾
echo ===============================
cd /d "%~dp0"
echo 目前專案資料夾：%cd%
echo.

echo ===============================
echo  [2] 檢查 flutter 指令是否存在
echo ===============================
where flutter >nul 2>nul
if errorlevel 1 (
    echo [ERROR] 找不到 flutter 指令。
    echo 請確認：這個視窗是由「Portable Dev Environment Launcher」啟動的。
    echo （先執行 PortableDev 的啟動批次檔，出現 cmd /k 的視窗後，
    echo   再在那個視窗裡執行 play.bat）
    echo.
    pause
    exit /b 1
)
echo OK，已找到 flutter。
echo.

echo ===============================
echo  [3] flutter doctor -v
echo ===============================
call flutter doctor -v
echo.

echo ===============================
echo  [4] 啟用 Web：flutter config --enable-web
echo ===============================
call flutter config --enable-web
echo.

echo ===============================
echo  [5] 下載套件：flutter pub get
echo ===============================
call flutter pub get
if errorlevel 1 (
    echo.
    echo [ERROR] flutter pub get 失敗，請往上查看錯誤訊息。
    pause
    exit /b 1
)
echo.

echo ===============================
echo  [6] 確認裝置：flutter devices
echo ===============================
call flutter devices
echo.

echo ===============================
echo  [7] 啟動 Chrome：flutter run -d chrome
echo ===============================
call flutter run -d chrome
if errorlevel 1 (
    echo.
    echo [ERROR] flutter run 執行失敗，請往上捲動看第一個紅字/ERROR。
    pause
    exit /b 1
)

echo.
echo ===============================
echo  ✅ Reversi Web Game 已結束
echo ===============================
pause
