@echo off
REM 深远GT1防盗控制器APP - 一键构建APK脚本
REM 使用方法：双击运行，或命令行执行

echo ================================================
echo   深远GT1防盗控制器APP - APK构建脚本
echo ================================================
echo.

REM 检查Flutter是否安装
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 未找到Flutter，正在尝试安装...
    echo.
    echo 请手动安装Flutter SDK：
    echo 1. 访问 https://flutter.dev/docs/get-started/install/windows
    echo 2. 下载并解压到 C:\flutter
    echo 3. 将 C:\flutter\bin 添加到系统PATH
    echo 4. 重新运行此脚本
    echo.
    echo 或者，使用Git Bash运行以下命令安装：
    echo   git clone https://github.com/flutter/flutter.git -b stable C:\flutter
    echo   set PATH=%%PATH%%;C:\flutter\bin
    echo   flutter doctor
    pause
    exit /b 1
)

echo [1/5] Flutter版本：
flutter --version
echo.

echo [2/5] 进入项目目录...
cd /d "%~dp0app"
if not exist "pubspec.yaml" (
    echo [错误] 未找到pubspec.yaml，请确认目录正确
    pause
    exit /b 1
)

echo [3/5] 获取依赖包...
flutter pub get
if %errorlevel% neq 0 (
    echo [错误] 依赖获取失败
    pause
    exit /b 1
)

echo [4/5] 构建Release APK...
flutter build apk --release
if %errorlevel% neq 0 (
    echo [错误] APK构建失败
    pause
    exit /b 1
)

echo.
echo ================================================
echo   APK构建成功！
echo   输出路径：app\build\app\outputs\flutter-apk\app-release.apk
echo ================================================
echo.
dir "build\app\outputs\flutter-apk\app-release.apk" 2>nul
echo.
echo 将APK文件传到安卓手机，设置->安装未知应用，即可安装。
pause
