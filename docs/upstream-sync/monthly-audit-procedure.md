# Monthly Upstream Audit Procedure（手動運用 runbook）

> **本 runbook の位置づけ**: Wave 0 で手動運用、Wave 4（Optional）で `make audit-upstream` にツール化予定。手順は 4 ステップ。所要時間: 30〜60 分。SSOT は本 doc + [`baseline-commits.json`](./baseline-commits.json) スキーマ。

## 前提

- 上流参照ハーネス URL / clone 先パス は内部の上流参照手順メモに集約（本 doc では `<上流参照>` プレースホルダで表記。OSS sanitize 規約）
- `gh` / `git` / `jq` / `python3` / `awk` が利用可能
- 既存 clone が `/tmp/<上流参照>` にある（初回は内部メモの clone 手順を参照）

## 手順

### Step 1 — 上流最新 SHA を取得・固定

```bash
REMOTE_SHA=$(git ls-remote <上流参照ハーネス URL> refs/heads/main | awk '{print $1}')
echo "remote main SHA: $REMOTE_SHA"
git -C /tmp/<上流参照> fetch origin "$REMOTE_SHA" --depth 1
LOCAL_SHA=$(git -C /tmp/<上流参照> rev-parse FETCH_HEAD)
test "$REMOTE_SHA" = "$LOCAL_SHA" || { echo "SHA mismatch"; exit 1; }
git -C /tmp/<上流参照> reset HEAD
# 既存 clone を再利用する場合、`checkout -- .claude/` は overlay のため
# 上流で削除/リネームされた path が stale として残る。manifest 前に明示掃除する。
rm -rf /tmp/<上流参照>/.claude
git -C /tmp/<上流参照> checkout FETCH_HEAD -- .claude/
```

判定:
- `SHA mismatch` が出たら fetch 失敗（network / repo 権限）。内部の上流参照手順メモを再確認
- 直前 baseline と SHA が同一なら audit スキップ可（drift 0 件想定）
- **`.claude/` を `rm -rf` してから checkout する**ことで、上流で削除/リネームされた path が manifest に残らない（reuse clone での drift 誤検出を防ぐ）

### Step 2 — drift 列挙（両側 sha256 manifest を path-key join）

```bash
# 上流側は Step 1 の `rm -rf` + `git checkout` で tracked file のみの clean state を保証済 → find で OK
(cd /tmp/<上流参照>/.claude && find . -type f -exec shasum -a 256 {} \;) | sort > /tmp/upstream_manifest.txt
# ローカル側は untracked file（.DS_Store / editor swap / 検証中の一時生成物）が混入すると
# 「local-only=removed」として bogus drift が ledger に append されるため、必ず `git ls-files` で
# tracked file に限定する（重要: dirty checkout 上で月次 audit を流しても ledger を汚染しない契約）
(cd .claude && git ls-files . | xargs -I{} shasum -a 256 ./{}) | sort > /tmp/local_manifest.txt
wc -l /tmp/upstream_manifest.txt /tmp/local_manifest.txt
```

drift 集計（`added` / `removed` / `modified` を分類）:

```bash
python3 - <<'PY'
def load(p):
    m = {}
    with open(p) as f:
        for line in f:
            line = line.rstrip()
            if not line: continue
            sha, path = line.split(None, 1)
            m[path] = sha
    return m
up = load("/tmp/upstream_manifest.txt")
lo = load("/tmp/local_manifest.txt")
added = sorted(set(up) - set(lo))
removed = sorted(set(lo) - set(up))
modified = sorted(p for p in (set(up) & set(lo)) if up[p] != lo[p])
print(f"added={len(added)} removed={len(removed)} modified={len(modified)}")
import json
out = {"added": added, "removed": removed, "modified": modified,
       "upstream_sha256": up, "local_sha256": lo}
with open("/tmp/drift.json", "w") as f:
    json.dump(out, f, indent=2)
PY
```

判定:
- `added + removed + modified` 合計件数 = 月次 audit の **検討対象 drift 件数**
- baseline 501049a（2026-05-20）時点の参照値は `added=178 / removed=19 / modified=77 / total=274`

### Step 3 — 4 区分判定（Reject 既定 → 評価軸）

順序を守る:

1. **Reject 既定（7 + 上流組織固有）を機械適用** で先に flag:
   - 特定ドメイン業務 / 週次月次レポート / メール連携 / STG 前提 UI / Project field 連携 / 実験物 / org・STG・secret 前提
   - 上流組織固有 path（`verify/` / `policies/` / `docs/plans/` / 組織ブランド資産）
2. **TOP10 explicit assignment**（前 baseline からの引き継ぎ + 新規 TOP10 候補があれば追加）
3. **評価軸で残りを分類**: `fork_immediacy × genericity × core_coupling ÷ maintenance_cost`
   - **Adopt now**: 4 軸ともに高 / 維持コスト低 → 即移植候補（W1〜3 のいずれか）
   - **Adapt later**: Core 結合度高だが汎用化要 / 維持コスト中以上 → 再ベースライン要（W2〜4 のいずれか）
   - **Document only**: 汎用性高だが Core 結合度低 → references/guide で言及するに留める
   - **Reject**: 汎用性低 + 維持コスト高 → 採否理由 + 再評価トリガ記録
4. **再評価トリガ運用**: 前 baseline で `Reject` だった record の再評価トリガが発火しているか確認 → 発火していれば本 baseline で **新 record として** classification を変更（既存 record は immutable）

判定結果はワークシート（CSV / Markdown 任意）に書き出し、Step 4 の append 入力にする。

### Step 4 — `baseline-commits.json` に新 record append

新 baseline_id を採番（例: `b2-<short_sha>`）し、以下の構造で `baselines[]` / `records[]` / `summary[]` 全てに append:

```bash
jq --argjson new_baseline '{"id":"b2-<short>","upstream_commit":"<full_sha>","upstream_commit_short":"<short>","captured_at":"YYYY-MM-DD","captured_by_issue":<N>}' \
   '.baselines += [$new_baseline]' \
   docs/upstream-sync/baseline-commits.json > /tmp/baseline-commits.json.new
# records[] と summary[] も同様に追記（実運用ではワークシート CSV → jq で一括 append するスクリプトを書く）
mv /tmp/baseline-commits.json.new docs/upstream-sync/baseline-commits.json
```

検証:

```bash
jq '.version, (.baselines | length), (.records | length), (.summary | length)' docs/upstream-sync/baseline-commits.json
jq '[.records[] | .baseline_id] | unique' docs/upstream-sync/baseline-commits.json
```

判定:
- baseline ID は `unique`
- records 件数 = previous_records + new_records（前 baseline の records は変えない）
- summary[] に新 baseline の集計が追加されている

### Step 5 — Epic 本文に反映 + 子 Issue 起票

- `gh issue edit <Epic 番号> --body-file ...` で Rolling Wave を更新（新 baseline の差分と TOP10 候補を冒頭に追記）
- Adopt now 区分の TOP 候補から順に Wave 子 Issue を起票（縦スライス / ≤ 20 ファイル / ≤ 8 タスク）

## Append-only ルール（重要）

- 既存 baseline の records[] / summary[] を**書き換えない**。再分類は新 baseline_id 配下で新 record を emit する
- 再評価トリガ発火による classification 変更は、`notes` 欄に「前 record `<rXXX>` から再評価」を明記して履歴を辿れるようにする

## 関連

- [`README.md`](./README.md) — `docs/upstream-sync/` の意図と各 file の役割
- [`baseline-commits.json`](./baseline-commits.json) — 採否台帳 SSOT（schema は `_schema` キー参照）
- [`drift-audit-2026-05-20.md`](./drift-audit-2026-05-20.md) — Wave 0 baseline の hand-curated audit table
- `.claude/rules/codex-review.md` — Codex 計画レビュー運用（月次 audit でも 4 区分判定の sanity check に利用可）
- 内部の上流参照手順メモ — URL / clone path / SHA 検証手順
- 内部の OSS sanitize 規約メモ — 公開境界での実名置換
