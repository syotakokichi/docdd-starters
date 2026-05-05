# PR 本文テンプレート

`/pr` Step 6 から参照される PR description の最小構成。`gh pr create --body-file` で投入するか、heredoc で展開する。

> **記法ルール**:
> - 見出し階層は `##` を用いる
> - `Closes #<N>` は **PR 本文側のみ** に書く（commit message に重複させない）
> - 1 PR = 1 Issue を原則とし、複数 Issue を閉じる場合は `Closes #<N>` 行を複数本並べる

---

```markdown
## 変更内容

- [主要な変更を 3 〜 5 行で要約]
- [Frontend / Backend / DocDD / DX のうち触ったレイヤーを明記]
- [既存の挙動が変わる場合はその旨を明記]

## テスト

- [ ] [変更レイヤーに対応する `make test-backend` / `make test-frontend` / `make test` を実行（PASS / N/A）]
- [ ] [`.claude/` の dx-docs 変更時は `make validate-claude`（PASS / N/A）]
- [ ] [DocDD 変更時は `make traceability`（PASS / N/A）]
- [ ] [`/verify` で軽量ブラウザヘルスチェックを実施（フロントエンド変更がある場合）]

## 関連

Closes #<N>
```

---

## 利用例

`/pr` Step 6 では、上記テンプレートを `/tmp/pr_body_<N>.md` に展開してから `gh pr create --body-file` で投入する:

```bash
ISSUE=42
PR_BODY="/tmp/pr_body_${ISSUE}.md"

# テンプレートをコピーして埋める
cp .claude/templates/pr-body.md "$PR_BODY"
# `<N>` を実 Issue 番号に置換し、各セクションを実装内容で埋める
sed -i.bak "s/<N>/${ISSUE}/g" "$PR_BODY" && rm -f "${PR_BODY}.bak"

# 内容を確認した上で gh pr create
gh pr create --base main --title "..." --body-file "$PR_BODY"
```

> **複数 Issue を閉じる場合**: `## 関連` セクションに `Closes #<N1>` / `Closes #<N2>` を改行区切りで並べる。1 行に複数書くと auto close が認識しないことがあるため、必ず行を分ける。

---

## 📋 後続 Issue で導入予定（forward reference の隔離）

| 参照先（未存在） | 用途 | 予定 Issue |
|--------------|------|----------|
| `landing_path_state` セクション | UI 変更時の auto close 抑止（`Refs #N` への切替） | **持ち込まない**（`screen-verify` がスコープ外のため） |
| `roadmap.md` 更新セクション | リリース計画との突合 | starter に roadmap なし。**持ち込まない** |
| 5-form bullet grammar lint | PR body の項目 grammar 検証 | **持ち込まない**（SubsCore 固有 lint） |
