#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

GHQ_ROOT="${WORKSPACES_SRC:-$HOME/Workspaces/src}"

case "$FILE_PATH" in
  "$GHQ_ROOT"/*)         exit 0 ;;
  "$HOME"/.claude/*)     exit 0 ;;
  /private/tmp/claude-*) exit 0 ;;
esac

printf '%s\n' "GHQ_ROOT ($GHQ_ROOT) 外のパスへのアクセスはブロックされました: $FILE_PATH" >&2
exit 2
