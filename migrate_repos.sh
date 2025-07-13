#!/bin/bash

# .envファイルから環境変数を読み込む
source .env

GITHUB_USER

# 元のリポジトリのOrganization（またはユーザー）
SRC_ORG="$SRC_ORG"

# 宛先リポジトリ情報
DEST_REPO_URL="https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${DEST_ORG}/${DEST_REPO_NAME}.git"

# 作業用ディレクトリ
WORK_DIR="./temp_clone_dir"
DEST_WORK_DIR="${DEST_WORK_DIR}"

# リポジトリ一覧ファイル
REPO_LIST_FILE="repos.txt"

# クリーンアップ＆ディレクトリ準備
rm -rf "$WORK_DIR" "$DEST_WORK_DIR"
mkdir -p "$WORK_DIR"

# 宛先リポジトリをクローン
echo "▶ Cloning destination repository..."
git clone "$DEST_REPO_URL" "$DEST_WORK_DIR"
if [ $? -ne 0 ]; then
  echo "宛先リポジトリのクローンに失敗しました。URLや認証情報を確認してください。"
  exit 1
fi

# 各リポジトリを処理
cd "$WORK_DIR" || exit 1

while read -r REPO_NAME; do
  SRC_REPO_URL="https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${SRC_ORG}/${REPO_NAME}.git"
  echo "▶ Cloning source: $REPO_NAME"

  git clone --depth 1 "$SRC_REPO_URL" "$REPO_NAME"
  if [ $? -ne 0 ]; then
    echo "クローン失敗: ${REPO_NAME}（スキップします）"
    continue
  fi

  echo "→ Copying contents from $REPO_NAME"
  mkdir -p "../destination_repo/${REPO_NAME}"
  rsync -av --exclude='.git' "$REPO_NAME/" "../destination_repo/${REPO_NAME}/"
done < "../$REPO_LIST_FILE"

# 最終コミット
cd "../destination_repo" || exit 1
git add .
git commit -m "$COMMIT_MESSAGE"

echo "すべての内容を宛先リポジトリにcommitしました"
echo "使用されたコミットメッセージ: $COMMIT_MESSAGE"
