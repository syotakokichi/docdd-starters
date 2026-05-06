#!/usr/bin/env bash
# codex-delegate.sh — Codex CLI に任意タスクを委譲する thin wrapper
# delegate-codex の !`bash .claude/skills/delegate-codex/codex-delegate.sh $ARGUMENTS` から呼ばれ、
# skill 読み込み時に Codex 出力が SKILL.md の context に展開される。
#
# Usage: bash .claude/skills/delegate-codex/codex-delegate.sh <args>
#   <args> は (a) JSON オブジェクト (b) 既存ファイル絶対パス (c) 自然文 のいずれか
#
# HOOK SAFETY 対象外 (非 hook スクリプト)
set -euo pipefail

# 引数受け渡し: --stdin が来たら標準入力から読む (SKILL.md からの heredoc 経由)
# それ以外は従来通り argv を結合する
if [ "${1:-}" = "--stdin" ]; then
  RAW="$(cat)"
else
  RAW="${*:-}"
fi

# stdin から来た末尾改行は trim (jq -e の判定や file 判定で空行が混じると壊れる)
RAW="${RAW%$'\n'}"

if [ -z "$RAW" ]; then
  echo "(Codex delegate skipped: empty ARGUMENTS)"
  exit 0
fi

CODEX_BIN="${CODEX_BIN:-codex}"
if ! command -v "$CODEX_BIN" &>/dev/null; then
  echo "(Codex delegate skipped: codex CLI not installed)"
  exit 0
fi

# 引数正規化: JSON -> ファイルパス -> 自然文
TASK=""
PROJECT_DIR=""
MODE="write"
TIMEOUT_S=600

# LOCAL EXTENSION (docdd-starters): JSON 風入力で jq 不在の場合に自然文扱いへ
# silent fallback すると mode=read_only / project_dir / timeout_s が ignored されたまま
# MODE=write (デフォルト) で `codex exec --full-auto` が走り read_only 契約が破れる。
# これを防ぐため、(1) 先頭の空白/改行を bash parameter expansion で除去してから JSON
# 判定する (Codex review P1 v2 対応: `\n{...,"mode":"read_only"}` の whitespace-prefixed
# JSON が natural-language 扱いにされるのを防止。BSD sed は先頭改行を行区切りとして扱い
# strip できないため `${var##pattern}` を使う)、(2) JSON 風入力では jq 必須で fail-fast する。
# (3) 検出対象は `{` のみ (オブジェクト)。`[frontend]` `[WIP]` 等の角括弧プレフィクスを
# 持つ自然文を JSON として誤判定しないよう、配列リテラル `[` は対象外とする (Codex review
# P2 対応: documented schema は object 形式 `{"task": "..."}` のみ)。
LEADING_WS="${RAW%%[![:space:]]*}"
TRIMMED_RAW="${RAW#"$LEADING_WS"}"
TRIMMED_FIRST_CHAR="${TRIMMED_RAW:0:1}"
if [ "$TRIMMED_FIRST_CHAR" = "{" ]; then
  if ! command -v jq &>/dev/null; then
    echo "(Codex delegate aborted: input looks like JSON but jq is not installed — install jq or pass natural language instead)" >&2
    exit 1
  fi
  if ! printf '%s' "$RAW" | jq -e . >/dev/null 2>&1; then
    echo "(Codex delegate aborted: input starts with '${TRIMMED_FIRST_CHAR}' but is not valid JSON — check syntax)" >&2
    exit 1
  fi
  TASK=$(printf '%s' "$RAW" | jq -r '.task // empty')
  PROJECT_DIR=$(printf '%s' "$RAW" | jq -r '.project_dir // empty')
  MODE=$(printf '%s' "$RAW" | jq -r '.mode // "write"')
  TIMEOUT_S=$(printf '%s' "$RAW" | jq -r '.timeout_s // 600')
elif [ -f "$RAW" ]; then
  TASK=$(cat "$RAW")
else
  TASK="$RAW"
fi

: "${PROJECT_DIR:=$(pwd)}"
[ -d "$PROJECT_DIR" ] || { echo "(Codex delegate skipped: project_dir not found: $PROJECT_DIR)"; exit 0; }
[ -n "$TASK" ] || { echo "(Codex delegate skipped: empty task)"; exit 0; }

# timeout 実装を解決 (macOS では coreutils の gtimeout を優先)
if command -v gtimeout &>/dev/null; then
  TIMEOUT_CMD=(gtimeout "${TIMEOUT_S}")
elif command -v timeout &>/dev/null; then
  TIMEOUT_CMD=(timeout "${TIMEOUT_S}")
# LOCAL EXTENSION (docdd-starters): gtimeout/timeout 不在時は Python ベースの timeout
# fallback を採用 (no-op `env` 退避は契約破りのため廃止)。Python も無ければ exit 1。
# subprocess.run(..., timeout=...) 経過後に TimeoutExpired を捕捉し exit 124 (gtimeout 互換)。
elif command -v python3 &>/dev/null; then
  echo "(Codex delegate: gtimeout/timeout not found, using python3 timeout fallback)" >&2
  TIMEOUT_CMD=(python3 -c '
import subprocess, sys
try:
    timeout_s = int(sys.argv[1])
except (IndexError, ValueError):
    sys.exit(2)
try:
    proc = subprocess.run(sys.argv[2:], stdin=sys.stdin, timeout=timeout_s)
    sys.exit(proc.returncode)
except subprocess.TimeoutExpired:
    sys.exit(124)
' "${TIMEOUT_S}")
else
  echo "(Codex delegate aborted: gtimeout / timeout / python3 are all missing — install coreutils or python3)" >&2
  exit 1
fi

PROMPT_FILE=$(mktemp)
trap 'rm -f "$PROMPT_FILE"' EXIT

if [ "$MODE" = "read_only" ]; then
  cat > "$PROMPT_FILE" <<__EOF__
${TASK}

## 環境メモ
- 作業ディレクトリ: ${PROJECT_DIR}
- **READ-ONLY モード**。ファイルを一切変更しないでください。
- 観察と findings のみを Markdown で出力してください。
__EOF__
  # LOCAL EXTENSION (docdd-starters): `--sandbox read-only` を明示的に渡し、ユーザーの
  # Codex config (デフォルト workspace-write) に依存せず Codex 側で OS レベルの書き込み
  # 禁止を強制する (Codex code review P1 v3 対応: prompt text のみでは不十分)。
  "${TIMEOUT_CMD[@]}" "$CODEX_BIN" exec --sandbox read-only -C "$PROJECT_DIR" - < "$PROMPT_FILE"
else
  cat > "$PROMPT_FILE" <<__EOF__
${TASK}

## 環境メモ
- 作業ディレクトリ: ${PROJECT_DIR}
- 書き込み権限あり。必要な範囲で編集・新規作成してください。
- project_dir の外側 (.mso/, /tmp/ state, 他プロジェクト) には書き込まない。
- 変更したファイル一覧と、変更しなかった理由を最後に要約してください。
__EOF__
  "${TIMEOUT_CMD[@]}" "$CODEX_BIN" exec --full-auto -C "$PROJECT_DIR" - < "$PROMPT_FILE"
fi
