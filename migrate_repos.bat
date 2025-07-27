@echo off
setlocal enabledelayedexpansion

REM === .env ファイルを読み込む ===
for /f "usebackq tokens=1,* delims==" %%A in (".env") do (
    set "%%A=%%B"
)

REM === 必要な変数を確認 ===
if not defined GITHUB_USER (
    echo [ERROR] GITHUB_USER が .env に定義されていません
    exit /b 1
)

REM === リポジトリ情報 ===
set "DEST_REPO_URL=https://%GITHUB_USER%:%GITHUB_TOKEN%@github.com/%DEST_ORG%/%DEST_REPO_NAME%.git"
set "DEST_WORK_DIR=%DEST_WORK_DIR%"
if "%DEST_WORK_DIR%"=="" set "DEST_WORK_DIR=destination_repo"

set "REPO_LIST_FILE=repos.txt"

REM === 宛先ディレクトリ削除 ===
if exist "%DEST_WORK_DIR%" (
    echo Removing existing directory: %DEST_WORK_DIR%
    rmdir /s /q "%DEST_WORK_DIR%"
)

REM === 宛先リポジトリをクローン ===
echo ▶ Cloning destination repository branch: %DEST_BRANCH%
git clone --branch %DEST_BRANCH% %DEST_REPO_URL% %DEST_WORK_DIR%
if errorlevel 1 (
    echo クローン失敗: 宛先リポジトリ（URL/ブランチ/認証情報）を確認して
    exit /b 1
)

REM === 各リポジトリを処理 ===
for /f "usebackq delims=" %%R in ("%REPO_LIST_FILE%") do (
    set "REPO_NAME=%%R"
    echo ▶ Cloning source (no history): !REPO_NAME!

    set "TMP_DIR=__tmp_!REPO_NAME!"
    if exist "!TMP_DIR!" rmdir /s /q "!TMP_DIR!"

    set "SRC_REPO_URL=https://%GITHUB_USER%:%GITHUB_TOKEN%@github.com/%SRC_ORG%/!REPO_NAME!.git"

    git clone --depth 1 --branch %SOURCE_BRANCH% !SRC_REPO_URL! "!TMP_DIR!"
    if errorlevel 1 (
        echo クローン失敗: !REPO_NAME!（スキップ）
        goto :continue_loop
    )

    echo → Copying contents from !REPO_NAME! (excluding .git)

    mkdir "%DEST_WORK_DIR%\!REPO_NAME!" 2>nul

    REM robocopy の利用（rsync の代替）
    robocopy "!TMP_DIR!" "%DEST_WORK_DIR%\!REPO_NAME!" /E /XD .git >nul

    rmdir /s /q "!TMP_DIR!"

    :continue_loop
)

REM === 最終コミット ===
cd "%DEST_WORK_DIR%" || exit /b 1
git add .
git commit -m "%COMMIT_MESSAGE%"
if errorlevel 1 (
    echo ※ 変更がないためコミットはスキップされた
)

echo 宛先リポジトリ '%DEST_REPO_NAME%'（ブランチ: %DEST_BRANCH%）にファイルを反映しました
