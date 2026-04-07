# 開発ガイド

okinawa-lodging-tax プロジェクトへの貢献ガイドです。
本プロジェクトは社の方針として [`landbase_ai_suite`](https://github.com/AI-LandBase/landbase_ai_suite) の開発規約を踏襲し、本プロジェクトの規模に合わせてスリム化したものを採用しています。

詳細な背景は [docs/tech-stack.md §2 開発規約](./docs/tech-stack.md#2-開発規約landbase踏襲) も参照してください。

---

## 目次

- [Issue 作成ガイド](#issue-作成ガイド)
- [Git ワークフロー](#git-ワークフロー)
- [ブランチ命名規則](#ブランチ命名規則)
- [コミット規約](#コミット規約)
- [PR 作成フロー](#pr-作成フロー)
- [コーディング規約](#コーディング規約)
- [テスト方針](#テスト方針)
- [セキュリティチェック](#セキュリティチェック)

---

## Issue 作成ガイド

新機能・バグ修正・ドキュメント追加に着手する前に、必ず GitHub Issue を作成します。Issue は実装の設計書であり、レビュー時の比較基準になります。

### Issue テンプレート

`.github/ISSUE_TEMPLATE/` のテンプレートから選択してください。

### 軽量版テンプレート（テンプレを使わない時の最低限）

```markdown
## 概要
[1-2行で何をするか]

## 背景・課題
[なぜ必要か / 現状の問題]

## 受け入れ基準
- [ ] [Must条件1]
- [ ] [Must条件2]

## 関連
- 関連 Issue: #XX
- 関連 ドキュメント: [docs/...](./docs/...)
```

### 優先度

| レベル | 説明 |
|---|---|
| **High** | 本番運用ブロッカー、セキュリティ問題、税計算ロジックの誤り |
| **Medium** | 新機能、UX 改善 |
| **Low** | 体裁修正、ドキュメント微修正 |

### 工数見積

landbase 同様の詳細な見積テンプレ（バッファ込み）を要するのは **High 優先度の Issue のみ**。それ以外は省略可。

詳細が必要な場合は landbase の [CONTRIBUTING.md 工数見積ガイドライン](https://github.com/AI-LandBase/landbase_ai_suite/blob/main/CONTRIBUTING.md) を参照。

---

## Git ワークフロー

[GitHub Flow](https://docs.github.com/ja/get-started/quickstart/github-flow) を採用します。

### 基本フロー

```
1. Issue 作成 → 2. ブランチ作成 → 3. 実装 → 4. PR 作成 → 5. レビュー → 6. Squash and Merge
```

### 🚨 重要原則

- **`main` ブランチへの直接プッシュは禁止**（PR 経由のみ）
- **`main` で直接作業しない**（必ずブランチを切る）
- 作業開始前に **`main` を最新化**してから分岐する

```bash
# 正しい手順
git checkout main
git pull origin main
git checkout -b feature/12-stay-form
```

---

## ブランチ命名規則

```
<type>/<issue番号>-<機能名>
```

| Type | 用途 | 例 |
|---|---|---|
| `feature/` | 新機能開発 | `feature/12-stay-form` |
| `bugfix/` | バグ修正 | `bugfix/15-tax-calc-rounding` |
| `hotfix/` | 緊急修正 | `hotfix/22-receipt-pdf-crash` |
| `refactor/` | リファクタリング | `refactor/18-extract-tax-service` |
| `docs/` | ドキュメント変更 | `docs/8-tech-stack` |
| `chore/` | ビルド・ツール設定 | `chore/3-rubocop-config` |

---

## コミット規約

### Conventional Commits 準拠

```
<type>(<scope>): <subject> (issue#<番号>)
```

### Type 一覧

| Type | 説明 | 例 |
|---|---|---|
| `feat` | 新機能 | `feat(app): 宿泊実績入力フォームを実装 (issue#12)` |
| `fix` | バグ修正 | `fix(app): 連泊時の税額計算を修正 (issue#15)` |
| `docs` | ドキュメント | `docs: tech-stack を追加 (issue#7)` |
| `refactor` | リファクタリング | `refactor(app): TaxCalculator を Service に抽出 (issue#18)` |
| `test` | テスト追加・修正 | `test(app): Stay モデルのテストを追加 (issue#12)` |
| `chore` | ビルド・ツール設定 | `chore(docker): compose の Postgres を 16 に固定 (issue#3)` |
| `perf` | パフォーマンス改善 | `perf(app): 月次集計の N+1 を解消 (issue#19)` |
| `style` | コードスタイル | `style: RuboCop 違反を修正 (issue#20)` |

### Scope（任意）

- `app` — Rails アプリ本体
- `docker` — Docker / Compose 設定
- `db` — データベース・マイグレーション
- `docs` — ドキュメント
- `infra` — Kamal / デプロイ設定

### 禁止事項

- ❌ **AI ツール署名の追加**（`Co-Authored-By: Claude` 等は付けない）
- ❌ **issue 番号の省略**（小さい雑多な作業でも必ず Issue を立てて番号を付ける）
- ❌ **`WIP` / `update` / `fix bug` 等の意味のないメッセージ**

### 良い例 / 悪い例

```bash
# ✅ GOOD
feat(app): 領収書PDF生成サービスを実装 (issue#21)
fix(app): 課税対象人数の整合チェックを修正 (issue#23)
docs: 紙台帳テンプレートを追加 (issue#9)

# ❌ BAD
update
fix bug
WIP
🤖 Generated with Claude Code
```

---

## PR 作成フロー

### 1. PR 作成

`.github/PULL_REQUEST_TEMPLATE.md` のテンプレートに沿って作成します。`gh pr create` で作る場合も同じ内容を `--body` に入れます。

### 2. レビュー対応

- レビューコメントには返答を残す（修正反映 or 議論）
- 修正は追加コミットで（force-push せず履歴を残す。Squash で消える）

### 3. マージ戦略: **Squash and Merge** を推奨

- 1 PR = 1 コミットとして `main` に記録される
- PR タイトルが Conventional Commits 形式のコミットメッセージになる
- WIP コミットや修正コミットが `main` に残らない

```
# PR内のコミット履歴（開発中）
- WIP: 初期実装
- fix: typo
- refactor: レビュー対応

↓ Squash and Merge

# main のコミット履歴
- feat(app): 領収書PDF生成サービスを実装 (issue#21)
```

### 4. マージ後

```bash
git checkout main
git pull origin main
# ローカルブランチは GitHub 側で自動削除される設定
```

---

## コーディング規約

> Rails アプリ実装着手後に詳細を追記します。現状は方針のみ。

### Ruby / Rails

- **Service Object パターン**: 複雑なビジネスロジック（税計算・PDF生成・エクスポート）は `app/services/` に切り出す
- **早期リターン**: ネストを深くしない
- **RuboCop 準拠**: `rubocop-rails-omakase` を採用。`bundle exec rubocop` で確認、`bundle exec rubocop -a` で自動修正
- **N+1 回避**: `includes` で eager loading、`Bullet` (development) で検出

### JavaScript / Stimulus

- Hotwire (Turbo + Stimulus) で記述
- SPA フレームワーク（React/Vue 等）は使わない

### データベース

- マイグレーションは `down` 実装必須（landbase 規約踏襲）
- **全カラムに `comment:` 必須**（税務監査時の自己説明性のため特に重要）
- インデックス追加は `algorithm: :concurrently` を活用（本番ロックを避ける）
- 詳細は [docs/tech-stack.md §5.4 マイグレーション戦略](./docs/tech-stack.md#54-マイグレーション戦略) 参照

---

## テスト方針

- **RSpec 必須**: すべての新機能・修正にテストを追加
- **カバレッジ閾値**: v0 段階では厳密な閾値を設けない。ただし税計算ロジック (`OkinawaTaxCalculator`) は**ケース網羅を強く推奨**
- **テスト種別**:
  - モデル spec
  - リクエスト spec（コントローラの代わりに request spec を使う）
  - system spec（領収書PDF生成・月次確定等のクリティカルパス）

> Rails アプリ実装着手後に具体的な実行コマンドを追記します。

---

## セキュリティチェック

### SQL インジェクション対策

```ruby
# ✅ DO: パラメータバインディング
Stay.where("guest_name LIKE ?", "%#{params[:q]}%")

# ❌ DON'T: 文字列補間
Stay.where("guest_name LIKE '%#{params[:q]}%'")
```

### Strong Parameters

```ruby
# ✅ DO
params.require(:stay).permit(:check_in_date, :nights, :guest_name, :num_guests, ...)
```

### 認証

```ruby
# 全コントローラの before_action で認証を必須にする
before_action :authenticate_user!
```

### XSS 対策

- ERB の自動エスケープを維持（`raw` / `html_safe` は原則使わない）

### CSRF 対策

- Rails 標準の `protect_from_forgery` を維持

---

## 参考リンク

- [プロジェクト技術スタック](./docs/tech-stack.md)
- [v0 要件定義](./docs/v0-requirements.md)
- [非機能要件](./docs/non-functional-requirements.md)
- [紙台帳テンプレート](./docs/paper-ledger-template.md)
- [GitHub Flow](https://docs.github.com/ja/get-started/quickstart/github-flow)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [landbase_ai_suite CONTRIBUTING.md](https://github.com/AI-LandBase/landbase_ai_suite/blob/main/CONTRIBUTING.md) — 詳細版（本プロジェクトはこれをスリム化したもの）
