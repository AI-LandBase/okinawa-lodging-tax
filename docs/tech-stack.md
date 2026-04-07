# 技術スタック（v0）

> **大方針**: `landbase_ai_suite` の設計思想・技術スタック・開発規約を踏襲する。
> 社の方針に沿って同じ運用知見・同じ規約で開発・保守できる状態を目指す。
>
> ただし本プロジェクトは「1施設=1インスタンスの汎用宿泊税アプリ」であり、
> landbase固有のマルチテナント (`client_code` スコープ) と AI機能 (anthropic gem) は採用しない。

---

## 0. 設計思想の継承方針

| 項目 | 方針 |
|---|---|
| 技術スタック | landbase と同一（Rails 8 / Ruby 3.4 / Postgres 16 / Devise / Solid Queue / RSpec 等） |
| 開発規約 | landbase の `CONTRIBUTING.md` を本プロジェクト向けにスリム化して採用 |
| ドキュメント体系 | `README.md` / `CONTRIBUTING.md` / `CLAUDE.md` / `ARCHITECTURE.md` の4本立てを踏襲（本プロジェクト規模に合わせて軽量化） |
| マルチテナント | **採用しない**（1施設1インスタンスのため `client_code` スコープ不要） |
| AI機能 | v0スコープ外。anthropic gem 等は v1以降に必要なら追加 |
| n8n / Mattermost | 採用しない（Rails単体構成） |

---

## 1. 技術スタック

### 1.1 ランタイム / フレームワーク

| 種別 | 採用 | 備考 |
|---|---|---|
| 言語 | **Ruby 3.4.6** | landbase合わせ |
| フレームワーク | **Rails 8.0.2.1** | landbase合わせ |
| アセットパイプライン | **Propshaft** | Rails 8 標準・landbase合わせ |
| Webサーバ | **Puma** + **Thruster** | landbase合わせ |

### 1.2 データベース / インフラ系

| 種別 | 採用 | 備考 |
|---|---|---|
| RDBMS | **PostgreSQL 16** | 税務データの長期保存・型の堅さ |
| キャッシュ | **Solid Cache** | Postgres backed・Redis不要 |
| ジョブキュー | **Solid Queue** | Postgres backed・Redis不要 |
| WebSocket | **Solid Cable** | Postgres backed |
| ローカル開発環境 | **Docker Compose** | Rails + Postgres を compose で起動 |

> **判断**: Solid 系で Postgres 1本に集約し、Redis を使わない。
> v0では2〜3人運用なのでこれで十分。将来スループットが問題になったら Sidekiq + Redis に移行可能。

### 1.3 認証

| 種別 | 採用 | 備考 |
|---|---|---|
| 認証ライブラリ | **Devise** + **devise-i18n** | landbase合わせ |
| 認証方式 | メール + パスワード | v0確定 |
| MFA / SSO | v0スコープ外 | v1以降に必要なら追加 |

> **判断**: Rails 8 ビルトイン認証ジェネレータも候補だったが、landbase が Devise を採用しているため**運用知見統一**を優先して Devise を採用。

### 1.4 履歴・監査

| 種別 | 採用 | 備考 |
|---|---|---|
| 変更履歴 | **paper_trail** gem | `whodunnit` で誰が変更したかを記録 |
| 静的解析 | **Brakeman** | landbase合わせ |
| N+1検出 | **Bullet** (development) | landbase合わせ |

> **判断**: paper_trail は landbase には未採用だが、本プロジェクトは税務データを扱い**変更履歴の保持が法令上必要**なため採用する。
> §[v0要件 §4](./v0-requirements.md#4-データモデルv0最小版) の方針通り、Stay の `updated_by_user_id` は速引き用、履歴の正は paper_trail のバージョンレコード側。

### 1.5 PDF生成 / 帳票

| 種別 | 採用 | 備考 |
|---|---|---|
| 領収書PDF生成 | **Prawn** | 純Ruby、依存軽量、Chromium不要 |
| PDF結合 | **combine_pdf** | landbase合わせ。月次まとめPDF生成時に利用 |
| CSV出力 | **csv** gem | Ruby 3.4+ で必須・landbase合わせ |

> **判断**: HTML→PDF (Grover) も検討したが、Chromium 同梱が Kamal デプロイを重くするため見送り。
> 領収書は要素が固定（宛名・金額・税額・但し書き）なので Prawn のレイアウトで十分。
> ロゴ・住所等は §1規律1 通り `config/facility.json` から読み込む。

### 1.6 フロントエンド

| 種別 | 採用 | 備考 |
|---|---|---|
| JS | **importmap-rails** + **Turbo** + **Stimulus** | Hotwire・landbase合わせ |
| CSS | **tailwindcss-rails** | landbase合わせ |
| ページネーション | **kaminari** | landbase合わせ |
| 国際化 | **rails-i18n** | 日本語ロケール |

> **判断**: SPA は不要。Hotwire で十分インタラクティブな画面が作れる。

### 1.7 テスト / 品質

| 種別 | 採用 | 備考 |
|---|---|---|
| テストフレームワーク | **RSpec** + **factory_bot** + **faker** | landbase合わせ |
| Lint | **rubocop-rails-omakase** | landbase合わせ |
| デバッグ | **debug** gem | Rails 8 標準 |

### 1.8 デプロイ / 本番

| 種別 | 採用 | 備考 |
|---|---|---|
| デプロイツール | **Kamal 2** | Rails 8公式・landbase合わせ |
| 実行環境 | Docker コンテナ | Kamal前提 |
| ホスティング | **未確定**（候補: 自社VPS / Hetzner / さくら） | landbaseと同居 or 別ホストかは要検討 |
| Active Storage | ローカルディスク + 永続ボリューム | landbase踏襲。S3移行は v1以降 |

> **要決定事項**: 本番ホスティング先。
> 「他社が deploy しても動く」汎用化規律と、自社運用のシンプルさのどちらを優先するか。
> 初期は自社1施設で動かすので、landbase の本番ホストに同居 or 別 VPS のどちらでも可。

---

## 2. 開発規約（landbase踏襲）

詳細は [`CONTRIBUTING.md`](../CONTRIBUTING.md)（別途整備）に記載するが、骨子は以下:

### 2.1 Git ワークフロー

- **GitHub Flow** 採用
- main 直接プッシュ禁止、PR 経由のみ
- ブランチ命名: `<type>/<issue番号>-<機能名>`
  - 例: `feature/12-stay-form`, `docs/8-tech-stack`
- type: `feature` / `bugfix` / `hotfix` / `refactor` / `docs` / `chore`

### 2.2 コミット規約

```
<type>(<scope>): <subject> (issue#<番号>)
```

- 例: `feat(app): 宿泊実績入力フォームを実装 (issue#12)`
- **issue番号必須**
- **AIツール署名禁止**（`Co-Authored-By: Claude` 等は付けない）
- Squash and Merge 推奨（1 PR = 1 コミット）

### 2.3 コーディング規約

- Service Object パターン（`app/services/`）
- 早期リターン推奨
- マイグレーションは `down` 実装必須・カラムに `comment:` 必須
- N+1 は eager loading で回避、`Bullet` で検出

### 2.4 セキュリティ

- パラメータバインディング徹底（SQLインジェクション対策）
- Strong Parameters
- Devise の `authenticate_user!` を全コントローラの before_action で必須
- ERB 自動エスケープを維持

### 2.5 テスト

- すべての新機能・修正に RSpec を追加
- モデルテスト・リクエストテスト・必要に応じて system spec
- カバレッジは厳密な閾値は設けない（v0段階）

---

## 3. ディレクトリ構成（予定）

```
okinawa-lodging-tax/
├── app/
│   ├── controllers/
│   ├── models/        # Stay, Receipt, MonthlyClose, User
│   ├── services/      # 税計算・領収書生成・エクスポート
│   │   ├── tax_rules/
│   │   │   ├── base.rb
│   │   │   └── okinawa.rb
│   │   ├── receipt_pdf_generator.rb
│   │   └── monthly_exporter.rb
│   ├── views/
│   └── javascript/controllers/  # Stimulus
├── config/
│   ├── facility.example.json    # 施設情報のサンプル（コミット対象）
│   └── facility.json            # 実体（.gitignore対象）
├── db/
│   ├── migrate/
│   └── seeds.rb                 # 初期スタッフ作成
├── docs/
│   ├── v0-requirements.md
│   ├── non-functional-requirements.md
│   ├── tech-stack.md            # 本ドキュメント
│   └── paper-ledger-template.md # 後続
├── spec/
├── compose.development.yaml
├── Dockerfile
├── Gemfile
├── README.md
├── CONTRIBUTING.md
└── CLAUDE.md
```

---

## 4. landbase と差分のある箇所まとめ

| 項目 | landbase | 本プロジェクト | 理由 |
|---|---|---|---|
| マルチテナント | あり (`client_code`) | **なし** | 1施設1インスタンス前提 |
| AI連携 | anthropic gem | なし | v0スコープ外 |
| ワークフロー | n8n | なし | 不要 |
| チャット | Mattermost | なし | 不要 |
| 履歴管理 | なし | **paper_trail 追加** | 税務データの法令要件 |
| PDF生成 | combine_pdf のみ | **Prawn 追加** | 領収書を1から生成する必要 |
| API認証 | Bearer Token | なし（v0） | 外部連携 v1以降 |

---

## 5. 未確定事項（v0着手前に決めたい）

- [ ] **本番ホスティング先**: landbase 同居 / 別 VPS / マネージド PaaS のいずれか
- [ ] **バックアップ戦略の具体実装**: Postgres ダンプの保存先・頻度（[非機能要件](./non-functional-requirements.md) §4 で RPO 24h と決定済み、実装手段は未定）
- [ ] **初期スタッフ作成 CLI のインターフェース**: `db:seed` か `bin/rails create_user` か

---

## 6. 採用しないことを明示

- ❌ **WordPress / WP系プラグイン** — 全社方針として技術スタックから除外
- ❌ **Sidekiq + Redis** — Solid Queue で十分
- ❌ **SPA フレームワーク (React/Vue)** — Hotwire で十分
- ❌ **Grover / Chromium 系 PDF** — Kamal デプロイを重くする
- ❌ **マルチテナント設計** — 1施設1インスタンスのため
