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

> **iPad Safari 対応**: v0 から **iPad Safari での動作を必須要件**とする（[v0要件 §5 画面構成](./v0-requirements.md#5-画面構成v0)）。Tailwind のレスポンシブユーティリティで iPad 以上の画面幅を保証範囲とし、スマートフォン縦画面の最適化は v0 スコープ外。タッチ入力時のフォーム UX（数値入力・日付ピッカー・プルダウン）は Hotwire + ネイティブ HTML フォームの範囲で対応する。

### 1.7 テスト / 品質

| 種別 | 採用 | 備考 |
|---|---|---|
| テストフレームワーク | **RSpec** + **factory_bot** + **faker** | landbase合わせ |
| Lint | **rubocop-rails-omakase** | landbase合わせ |
| デバッグ | **debug** gem | Rails 8 標準 |

### 1.8 ハードウェア前提（v0）

アプリ動作要件（技術要件）と、将来の販売モデル側の同梱構成を分離して扱う。詳細な判断背景は [`docs/decisions.md` 2026-04-08](./decisions.md) 参照。

| 層 | 要件 |
|---|---|
| **アプリの動作要件**（必須） | モダンブラウザ（Chrome / Safari / Edge 最新版）が動作する任意の PC。OS は問わない。**推奨は Mac**（販売キットで同梱するため動作検証・サポート窓口を集約） |
| **iPad**（オプション） | iPad Safari で現場入力ができること。採用しない事業者は紙台帳運用で完結できる |
| **Square**（決済端末として前提） | v0 はアプリから API を叩かず、スタッフが Square 端末で決済し金額をアプリに手入力する。Stay モデルに `payment_method` カラムで Square 運用の備えのみ持つ。API 連携は v1 |
| **販売モデル側の同梱構成**（v1 以降の配布形態） | **Mac + iPad + Square** をプリインストール済み端末キットとして同梱し、県の宿泊税関連助成金制度（制度名・要件は今後確認）を活用して販売する構想。アプリの動作要件を縛るものではない |

> **運用形態は事業者が選べる**: (1) 紙台帳ベース運用（ベースライン）、(2) iPad 現場入力運用（オプション）。システム側はどちらにも耐えることを v0 から要件化する（[v0要件 §2.0](./v0-requirements.md#20-動作前提デバイス)）。

### 1.9 デプロイ / 本番

| 種別 | 採用 | 備考 |
|---|---|---|
| デプロイツール | **Kamal 2** | Rails 8公式・landbase合わせ |
| 実行環境 | Docker コンテナ | Kamal前提 |
| ホスティング | **未確定**（後述の選択肢から決定） | |
| Active Storage | ローカルディスク + 永続ボリューム | landbase踏襲。S3移行は v1以降 |

#### ホスティング候補と評価軸

| 案 | 候補 | メリット | デメリット / リスク |
|---|---|---|---|
| **A. landbase 同居** | 既存 landbase 本番ホスト | デプロイパイプライン共通化、インフラコスト削減、運用知見の集約 | **landbase 障害時に税務系まで巻き込まれ、サービス影響範囲が広がる**。バックアップ・保存期間ポリシーが landbase の運用に引きずられる |
| **B. 別 VPS（自社管理）** | Hetzner / さくらVPS / ConoHa | 障害ドメイン分離、税務データの保管ポリシーを独立に持てる、Kamal の知見をそのまま流用 | サーバ管理の負担が二重化、監視・バックアップを別途構築 |
| **C. マネージド PaaS** | Fly.io / Render | OS管理不要、スケールが楽 | 月額が VPS より高め、Postgres マネージド前提でデータ持ち出し制約あり、Kamal の知見が活きない |

> **判断軸**: 税務データは保存期間・バックアップ・分離性の要求が強い（[非機能要件 §3](./non-functional-requirements.md)）。
> A は短期的には楽だが、**「税務データを landbase の障害ドメインに巻き込む」リスク**が長期で重い。
> 現時点の有力案は **B（別 VPS）**。最終決定は v0実装着手前に行う。

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

## 5. 運用方針メモ

### 5.1 バックアップ戦略

[非機能要件 §4](./non-functional-requirements.md) で **RPO 24h / RTO 1h** と決定済み。これを満たす方針案:

- **DBバックアップ**: 1日1回 `pg_dump` でフルバックアップを取得し、別ロケーションのオブジェクトストレージ（S3互換: AWS S3 / Cloudflare R2 等）に転送
- **Active Storage**: 領収書PDF等のファイルも同じ S3互換ストレージへ日次同期
- **暗号化**: 転送時 TLS、保管時はストレージ側の暗号化機能を有効化
- **保管期間**: [非機能要件 §3](./non-functional-requirements.md) の「**業務上7年・システム上10年**」要件に揃える
  - 直近1ヶ月: 日次世代（30本）
  - 直近1年: 月次世代（12本）
  - それ以降: 年次世代を 10年保持
- **検証**: 月1回リストアテストを実施（手順は実装フェーズで整備）

> **未確定事項**: 具体的なストレージ先（R2 / S3 / Backblaze B2 等）、世代管理ツール（[wal-g](https://github.com/wal-g/wal-g) / [pgBackRest](https://pgbackrest.org/) / 自前 cron）の選定。
> v0着手前に確定する。

### 5.2 初期スタッフ作成（1人目の作成方法）

**基本線: `db:seed` を採用する**（landbase踏襲）

landbase の `db/seeds.rb` は `find_or_create_by!` で**冪等**に書かれており、何度実行しても安全。本プロジェクトも同方式を採用する。

```ruby
# db/seeds.rb（イメージ）
if Rails.env.production? && User.count.zero?
  User.find_or_create_by!(email: ENV.fetch("INITIAL_ADMIN_EMAIL")) do |user|
    user.name = ENV.fetch("INITIAL_ADMIN_NAME")
    user.password = ENV.fetch("INITIAL_ADMIN_PASSWORD")
  end
end
```

**ポイント**:
- 初期スタッフのメール・パスワードは環境変数経由で渡す（リポジトリにコミットしない）
- `User.count.zero?` ガードで2回目以降は no-op（冪等性）
- 2人目以降は1人目がログインしてユーザー管理画面から追加

**将来の拡張余地**: 「複数施設へのロールアウト」や「他社オーナーへの配布」を見据えると、`bin/rails create_user EMAIL=... NAME=...` のような専用 idempotent rake タスクの方が**自動化スクリプトに組み込みやすい**。v1以降でデプロイ自動化を整備する際に併せて導入を検討する。

### 5.3 監視・ロギング

- **方針**: **landbase と同等構成を前提**とする。landbase 側で APM / エラー追跡 / ログ収集を導入したら、本プロジェクトも同じツール（Sentry / Datadog / OpenTelemetry 等）で揃える
- **v0時点**: landbase が現状観測ツール未導入のため、本プロジェクトも以下のミニマム構成でスタート:
  - Rails 標準ログ + `lograge` 程度で構造化
  - エラー通知は最低限メール or Slack Webhook
  - 監視閾値の具体値は [非機能要件 §7](./non-functional-requirements.md) 参照
- **v1以降**: landbase 側で観測基盤が整備された段階で同期して導入。ログ集約・APM・メトリクスを揃える

> **理由**: 観測ツールはチーム横断で揃えると運用負担が大きく下がる。先行して別ツールを入れると後で揃え直しになるため、landbase に追従する。

### 5.4 キッティング方針（v1 以降の課題）

v0 ではスコープ外だが、将来の **助成金活用キット販売モデル**（[decisions.md 2026-04-08](./decisions.md)）に向けて、以下を v1 以降に整備する必要がある:

- **Mac キッティング手順書**: Docker Desktop + okinawa-lodging-tax の初期セットアップを自動化する shell スクリプト or Ansible playbook
- **iPad キッティング手順書**: Safari ブックマーク・ホーム画面追加・自動ログイン設定・画面ロック設定
- **Square 連携セットアップ**: 端末ペアリング手順、v1 では API 連携セットアップ
- **初期ユーザー投入自動化**: `db:seed` or 専用 rake タスクを助成金配布フロー向けに整備
- **助成金申請用資料テンプレ**: 事業者が申請書類を作成する際のシステム仕様書・導入効果試算テンプレ

> v0 では自社民泊1施設のドッグフーディングに集中し、キッティングは手作業で回す。自動化は v0 完了後、他事業者への横展開開始時に着手する。

### 5.5 マイグレーション戦略

税務系システムはスキーマ変更がシビアになりがち（過去データの再計算可能性、監査証跡）。以下の思想で運用する:

- **基本: forward-only migration**
  - Rails 標準 `bin/rails db:migrate` を用い、リリース後の rollback は原則行わない
  - 各 migration は landbase 規約通り `down` を実装し、開発環境での巻き戻しのみで使用
- **破壊的変更（カラム削除・型変更等）の扱い**:
  - **段階移行**: 「新カラム追加 → データ移行 → 旧カラム参照削除 → 旧カラム削除」を別リリースに分ける
  - 過去の Stay の税額再計算が必要なケースは、税ルールの `version` フィールドで吸収する（[v0要件 §6](./v0-requirements.md#6-税計算ロジックプラグイン構造) 参照）
  - スキーマレベルの大変更が必要な場合は **view 分離** や **履歴テーブル（paper_trail のバージョン）** で旧仕様の参照経路を残す
- **税率・条例改定への対応**:
  - スキーマ変更ではなく **`src/tax-rules/okinawa.ts` の `version` 更新**で吸収する
  - 過去 Stay には保存時の `tax_rule_version` を残し、再計算時に当時のロジックを呼べるようにする
- **マイグレーション要件**:
  - landbase 規約通り `down` メソッド実装必須
  - 全カラムに `comment:` 必須（税務監査時の自己説明性のため特に重要）
  - インデックス追加は `algorithm: :concurrently` を活用（本番ロックを避ける）

> 関連: [非機能要件 §3 保存期間](./non-functional-requirements.md) / [§5 改ざん耐性](./non-functional-requirements.md)

---

## 6. 未確定事項（v0着手前に決めたい）

- [ ] **本番ホスティング先**: §1.9 のA / B / Cから決定（現状はB有力）
- [ ] **バックアップ実装ツール**: §5.1 の wal-g / pgBackRest / 自前 cron から選定
- [ ] **バックアップ保管先**: §5.1 の R2 / S3 / B2 等の選定
- [ ] **`lograge` 等のログ整形 gem 採用可否**: §5.3

---

## 7. 採用しないことを明示

- ❌ **WordPress / WP系プラグイン** — 全社方針として技術スタックから除外
- ❌ **Sidekiq + Redis** — Solid Queue で十分
- ❌ **SPA フレームワーク (React/Vue)** — Hotwire で十分
- ❌ **Grover / Chromium 系 PDF** — Kamal デプロイを重くする
- ❌ **マルチテナント設計** — 1施設1インスタンスのため
