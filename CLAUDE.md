# CLAUDE.md - Claude 向けクイックリファレンス

このドキュメントは Claude（AI 開発アシスタント）がこのプロジェクトを素早く理解し、適切に支援するためのクイックリファレンスです。

**詳細な開発規約は [`CONTRIBUTING.md`](./CONTRIBUTING.md)、技術選定は [`docs/tech-stack.md`](./docs/tech-stack.md) を参照してください。**

---

## プロジェクト概要

**okinawa-lodging-tax** — 沖縄県宿泊税の税額算定・集計・帳簿保存・領収書発行・申告用データ出力を行うアプリ。

### 性格

- **1施設=1インスタンスの汎用アプリ**（マルチテナント SaaS ではない）
- **第一の顧客は本リポジトリ運営会社の自社民泊**（ドッグフーディング前提）
- 会社運営のため **スタッフ2〜3人のマルチユーザー** で運用される
- 社の方針として `landbase_ai_suite` の技術スタックと開発規約を踏襲

### 現在のフェーズ

**v0 要件定義フェーズは完了**。実装着手前。次のステップは [README.md の「次のステップ」](./README.md#次のステップ) 参照。

---

## 技術スタック（要点）

- **Rails 8.0.2.1** / **Ruby 3.4.6**
- **PostgreSQL 16**
- **Devise** (認証) / **Solid Queue・Cache・Cable**（Redis 不要）
- **paper_trail**（履歴・税務監査）
- **Prawn**（領収書 PDF）/ **combine_pdf**（PDF 結合）
- **Tailwind CSS** + **Hotwire** (importmap / Turbo / Stimulus)
- **RSpec** + factory_bot + faker
- **Kamal 2** デプロイ
- **Docker Compose** ローカル環境

詳細は [`docs/tech-stack.md`](./docs/tech-stack.md) を参照。

---

## 主要ドキュメント（読む順序）

| 順序 | ドキュメント | 内容 |
|---|---|---|
| 1 | [`README.md`](./README.md) | プロジェクト全体像、ステータス、次のステップ |
| 2 | [`docs/v0-requirements.md`](./docs/v0-requirements.md) ⭐ | v0 機能要件、データモデル、税計算 IF |
| 3 | [`docs/non-functional-requirements.md`](./docs/non-functional-requirements.md) | 非機能要件（保存期間 / RPO・RTO / 監査 / セキュリティ） |
| 4 | [`docs/tech-stack.md`](./docs/tech-stack.md) | 技術スタック選定（landbase 踏襲）と運用方針 |
| 5 | [`docs/paper-ledger-template.md`](./docs/paper-ledger-template.md) | 紙台帳テンプレート（Stay と 1:1 対応） |
| 6 | [`CONTRIBUTING.md`](./CONTRIBUTING.md) | 開発規約・コミット規約・PR フロー |

> [`docs/requirements.md`](./docs/requirements.md) は SaaS拡張時の参考資料。**v0 のソースオブトゥルースは `v0-requirements.md`**。

---

## よく使うコマンド

> Rails アプリ実装着手後に追記します。現状は雛形のみ。

```bash
# (TBD) make up        # Docker Compose 起動
# (TBD) make down      # 停止
# (TBD) make test      # RSpec 実行
# (TBD) bin/rails console
```

---

## 重要な設計原則

### 規律 1: ユーザー固有データはコードに書かない

施設名・住所・登録番号・チャネル名・領収書ロゴ等は **`config/facility.json`** に集約する。
コード内ハードコードは禁止。

### 規律 2: 税ロジックは Service Object に切り出す

`app/services/okinawa_tax_calculator.rb` (仮) のように、税計算ロジックは Rails の Service Object として独立させる。
条例改定への対応は **`tax_rule_version` フィールド** で吸収し、過去の Stay は当時の version で再計算可能にする。

> **対応自治体スコープ（沖縄限定 vs 多自治体）はチーム議論で確定する論点**。現状ドキュメントは多自治体想定の表現が混在しているが、議論結果次第で整理する。

### 規律 3: 領収書・帳票はテンプレート化

ロゴ・住所・但し書き等はコードに直書きせず、テンプレート + 設定で差し替え可能にする。

### マルチテナントは採用しない

landbase との大きな差分。本プロジェクトは 1 施設 1 インスタンス前提のため `client_code` スコープは不要。

---

## コミット・ブランチ規約（要点）

詳細は [`CONTRIBUTING.md`](./CONTRIBUTING.md) を参照。

### ブランチ

```
<type>/<issue番号>-<機能名>
例: feature/12-stay-form, docs/8-tech-stack
```

### コミット

```
<type>(<scope>): <subject> (issue#<番号>)
例: feat(app): 領収書PDF生成サービスを実装 (issue#21)
```

### 禁止事項

- ❌ `main` ブランチへの直接プッシュ
- ❌ AI ツール署名（`Co-Authored-By: Claude` など）
- ❌ Issue 番号なしのコミット
- ❌ `--no-verify` で hook をスキップ

### マージ戦略

**Squash and Merge** を推奨（1 PR = 1 コミット）。

---

## セキュリティチェック（要点）

```ruby
# 1. SQL インジェクション対策（パラメータバインディング）
Stay.where("guest_name LIKE ?", "%#{params[:q]}%")  # ✅
Stay.where("guest_name LIKE '%#{params[:q]}%'")     # ❌

# 2. Strong Parameters
params.require(:stay).permit(:check_in_date, :nights, :guest_name, ...)

# 3. 認証
before_action :authenticate_user!
```

詳細は [`CONTRIBUTING.md` セキュリティチェック](./CONTRIBUTING.md#セキュリティチェック) 参照。

---

## 自動実行ポリシー

### 確認なしで実行可能

- ファイル読み取り: Read, Grep, Glob
- 状態確認: `git status`, `git log`, `git diff`, `gh pr list`
- ドキュメント編集（`docs/`, `README.md`, `CONTRIBUTING.md`, `CLAUDE.md`）
- ブランチ作成・切替（main 以外への切替）

### 必ず確認が必要

- データベース操作（`db:migrate`, `db:drop`, `db:reset`）
- `git push` / `gh pr merge` / `gh pr create`
- 本番環境への操作（Kamal デプロイ、環境変数変更）
- ファイル削除（`rm`, `git rm`）

**原則**: 永続的な変更や元に戻せない操作は必ず確認する。

---

## メモリとの関係

ユーザーの auto memory に本プロジェクトの背景情報が保存されています:

- `okinawa_lodging_tax.md` — プロジェクト性格・運営状況・landbase との関係
- `feedback_tech_stack_exclusions.md` — 技術スタック方針（Rails 主軸 / WordPress 不採用）
- `landbase.md` — landbase_ai_suite の概要

メモリの内容と本ドキュメントが食い違っている場合は、**本ドキュメント（リポジトリ内）を優先**してください。メモリは観測時点のスナップショットです。

---

**Last Updated**: 2026-04-07
