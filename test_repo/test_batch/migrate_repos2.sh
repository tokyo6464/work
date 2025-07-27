#!/bin/bash

# .envファイルから環境変数を読み込む
source .env

# 各種リポジトリ情報
DEST_REPO_URL="https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${DEST_ORG}/${DEST_REPO_NAME}.git"
DEST_WORK_DIR="${DEST_WORK_DIR:-./destination_repo}"
REPO_LIST_FILE="repos.txt"

# クリーンアップ＆宛先リポジトリをクローン（特定ブランチを指定）
rm -rf "$DEST_WORK_DIR"
echo "▶ Cloning destination repository branch: $DEST_BRANCH"
git clone --branch "$DEST_BRANCH" "$DEST_REPO_URL" "$DEST_WORK_DIR"
if [ $? -ne 0 ]; then
  echo "宛先リポジトリのクローンに失敗しました。URL、ブランチ、認証情報を確認してください。"
  exit 1
fi

# 各リポジトリを処理
while read -r REPO_NAME; do
  SRC_REPO_URL="https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${SRC_ORG}/${REPO_NAME}.git"
  echo "▶ Cloning source (no history): $REPO_NAME"

  TMP_DIR="./__tmp_${REPO_NAME}"
  rm -rf "$TMP_DIR"

  # 指定ブランチで履歴なしクローン
  git clone --depth 1 --branch "$SOURCE_BRANCH" "$SRC_REPO_URL" "$TMP_DIR"
  if [ $? -ne 0 ]; then
    echo "⚠ クローン失敗: ${REPO_NAME}（スキップします）"
    continue
  fi

  echo "→ Copying contents from $REPO_NAME (excluding .git)"
  mkdir -p "${DEST_WORK_DIR}/${REPO_NAME}"
  rsync -av --exclude='.git' "$TMP_DIR/" "${DEST_WORK_DIR}/${REPO_NAME}/"

  rm -rf "$TMP_DIR"
done < "$REPO_LIST_FILE"

# 最終コミット
cd "$DEST_WORK_DIR" || exit 1
git add .
git commit -m "$COMMIT_MESSAGE" || echo "※ 変更がないためコミットはスキップされました"

echo "宛先リポジトリ '$DEST_REPO_NAME'（ブランチ: ${DEST_BRANCH}）にファイルを反映しました"
echo "使用されたコミットメッセージ: $COMMIT_MESSAGE"
