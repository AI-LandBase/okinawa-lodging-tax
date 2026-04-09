# v0 要件定義 — 民泊MVP版

> v0は「自社小規模民泊（1施設）でスタッフ2〜3人が日常運用できる最小機能」のスコープ。
> 将来「他の小規模宿泊事業者にも汎用的に提供できる1施設1インスタンスのアプリ」へ育てる前提。
> 既存の [`requirements.md`](./requirements.md) は SaaS拡張時に参照する将来要件として残す。

## v0の運用前提

| 項目 | 値 |
|---|---|
| 利用ユーザー | スタッフ2〜3人（同社内） |
| ロール | 全員同権限（ロール分けなし） |
| 月次集計・エクスポート・申告データ出力 | 全員可 |
| 対象施設 | 1施設 |
| 構成 | 独立Railsアプリ（landbase_ai_suite との同居はしない） |

---

## 0. このドキュメントの位置づけ

| ドキュメント | スコープ | 状態 |
|---|---|---|
| `v0-requirements.md` ⭐ | ユーザー自身の民泊で動く最小版 | **これから実装** |
| `requirements.md` | SaaS拡張時の将来要件 | 参考 |

---

## 1. 設計原則（汎用化のための3規律）

v0は「自分用ミニマム」だが、将来「1施設=1インスタンスの汎用アプリ」へ育てるため、最初から守る規律。

### 規律1: ユーザー固有データはコードに書かない

施設名・住所・電話番号・登録番号等のテキスト設定は **Rails credentials** (`Rails.application.credentials.facility`) から読む。
ロゴ等のバイナリ資産は **`app/assets/images/facility/*`** に置き、`.gitignore` で除外する。
他人が deploy する時は credentials と assets を差し替えるだけで動くこと。コードへのハードコードは禁止。

> 当初は `config/facility.json` への集約を想定していたが、Kamal デプロイ時の受け渡し方法を決める負担が大きいこと、Rails credentials で同等の要件が満たせることから方針変更した。詳細は [`docs/decisions.md` 2026-04-07: config/facility.json の概念を v0 では採用しない](./decisions.md) 参照。

### 規律2: 税ロジックを自治体ごとに分離

```
app/services/tax_rules/
  base.rb         ← 共通インターフェース（抽象基底クラス）
  okinawa.rb      ← 沖縄県宿泊税
```

各ルールは `TaxRules::Base` を継承し、共通インターフェース `#calculate(input)` を実装する。
将来 `kyoto.rb` `tokyo.rb` を追加するだけで他自治体対応が可能。条例改定への対応は **`tax_rule_version`** で吸収する（§4 / §6 参照）。

### 規律3: 領収書・帳票はテンプレート化

ロゴ・住所・但し書きをコードに直書きせず、テンプレート + 設定で差し替え可能にする。

---

## 2. スコープ

### 2.0 動作前提デバイス

**アプリ動作要件（技術要件）**:

- **サーバ側**: Docker で動作するためホスト OS は任意（Linux 想定）
- **スタッフ PC**: モダンブラウザ（Chrome / Safari / Edge の最新版）が動作する任意の PC。OS は問わない
  - **推奨は Mac** — 販売キットで同梱するため動作検証・サポート窓口を集約したい
- **iPad**（オプション）: iPad Safari で現場入力ができること。必須ではなく、採用しない事業者は紙台帳運用で完結できる
- **Square**（決済端末として前提）: v0 ではアプリから API を叩かない。決済はスタッフが Square 端末で処理し、金額をアプリに手入力する。Square API 連携は v1 以降

**ビジネスモデル側の同梱構成（参考）**:

上記の技術要件とは別に、将来の販売モデルでは **Mac + iPad + Square をプリインストール済み端末キットとして同梱する**ことを想定する。ただしこれは配布形態の話であり、アプリの動作要件を縛るものではない。詳細は [`README.md` #起点と方向性](../README.md#起点と方向性) と [`docs/decisions.md` 2026-04-08](./decisions.md) 参照。

**運用形態の選択肢**: 事業者は以下のどちらかを選べる。システム側はどちらの運用にも耐えること。

1. **紙台帳ベース運用**（ベースライン）: 現場では紙に記入、別途 PC から転記入力する。既存の [紙台帳テンプレート](./paper-ledger-template.md) の運用そのまま
2. **iPad 現場入力運用**（オプション）: 受付時に iPad で直接 Stay を入力、紙台帳は使わない or 通信障害時の予備として残す

### v0でやること

| # | 機能 | 内容 |
|---|---|---|
| 1 | 宿泊実績の手入力 | 紙台帳から1件ずつ転記する想定の単純フォーム |
| 2 | 宿泊税の自動計算 | 入力値から税額を計算してレコードに保存 |
| 3 | 月次集計 | 当月の人数・料金・税額の合計を表示 |
| 4 | 領収書PDF出力 | 1宿泊1枚。宿泊料金と宿泊税を分離表示 |
| 5 | 月次データのエクスポート | 申告書転記用のCSV/PDF |
| 6 | ユーザー認証 | スタッフ2〜3人がそれぞれ自分のアカウントでログイン |
| 7 | ユーザー追加・無効化 | 管理画面でユーザーの追加・無効化ができる（コード変更不要） |

#### 入力単位の方針

v0では **「1予約 = 1 Stayレコード」** を正とする。

- 1予約は1人または1グループの連続した宿泊を表す
- 連泊は `nights` カラムに泊数を持ち、Stayは増やさない
- 1予約で複数部屋を取るケースは v0では想定しない（民泊1棟貸し前提）
  - もし発生したら「予約を分割して2レコード入力する」運用で吸収
- **税計算上の単位**は「1人1泊」だが、これはレコード単位ではなく**計算ロジック内部で導出**する
  - 例: `tax_amount = perNightTax × nights × num_taxable_guests`

この方針により紙台帳も「1予約1行」で書ける。

#### エクスポートフォーマットの方針

v0時点では「申告書への手転記を楽にする」ことが目的。電子申告(eLTAX等)は v1以降。

想定するCSVカラム例:

| カラム | 内容例 |
|---|---|
| 宿泊日 | 2026-04-01 |
| チェックアウト日 | 2026-04-03 |
| 泊数 | 2 |
| 代表者名 | 山田 太郎 |
| 総人数 | 3 |
| 課税対象人数 | 3 |
| 免除人数 | 0 |
| 1人1泊宿泊料金 | 8000 |
| 課税対象合計 | 48000 |
| 宿泊税額 | 960 |
| チャネル | Airbnb |
| 予約番号 | XYZ123 |
| 備考 | (任意) |

将来の自治体様式・eLTAX対応は **「Exporterプラグイン」として `src/exporters/` に追加**する想定。
税ルール同様、v0では1個（汎用CSV）だけ実装し、構造だけ拡張可能にしておく。

### v0でやらないこと（明示）

- ❌ ロールベース権限（v0は全員同権限）
- ❌ SSO（landbase_ai_suite との SSO 連携は v1以降）
- ❌ 多要素認証
- ❌ 設定UI画面の本格実装（最低限のユーザー追加・無効化のみ）
- ❌ 自治体マスタのDB管理（コード内分岐で十分）
- ❌ OTA連携・iCal取込（v1以降）
- ❌ 宿泊者名簿の自動生成・提出（v1以降）
- ❌ マルチ施設対応
- ❌ 監査ログの本格実装（変更履歴の最低限のみ持つ。詳細は §[非機能要件](./non-functional-requirements.md) 参照）
- ❌ 電帳法対応の本格化（最低限の保存のみ）

> 認証・複数ユーザー・最低限の変更履歴は **v0必須** に変更（会社運営で2〜3人スタッフが触るため）。
> 詳細は §4 と [docs/non-functional-requirements.md](./non-functional-requirements.md) §4・§7 を参照。

---

## 3. 想定ユースケース

### UC-1: 当日分の宿泊実績入力（紙台帳ベース運用）

1. スタッフが自分のアカウントでログインし、紙台帳を見ながら直近のチェックイン分を入力
2. フォームに日付・人数・料金・代表者名等を入力
3. 保存ボタンで税額が自動計算され、一覧に追加される
4. 入力者（誰が登録したか）はレコードに自動記録される

### UC-1': 受付時の現場入力（iPad オプション運用）

1. スタッフが iPad Safari で自分のアカウントにログイン
2. 受付カウンターでゲストを迎えながら、iPad のフォームに直接 Stay を入力する
3. Square 端末で決済を処理し、金額をアプリに入力（`payment_method` に `square` を記録）
4. 保存ボタンで税額が自動計算され、一覧に追加される
5. この運用では紙台帳は必須ではない（通信障害時の予備として残すかは事業者判断）

### UC-2: 月次の申告準備

1. 月初にスタッフの誰かが「月次集計画面」で前月分の合計を確認
2. 「エクスポート」から申告書転記用の CSV/PDF をダウンロード（実行時刻と実行者は `MonthlyExport` レコードに記録される）
3. 紙の申告書に転記して県へ提出
4. v0 では月次の編集ロックは持たない。エクスポート済の月の Stay を編集する場合は警告表示で誤操作を防ぐが、編集自体は許可する。事後監査は paper_trail の履歴に委ねる
5. 法的な「確定」は条例第10条の申告納入の時点であってアプリ内状態ではない（[`docs/decisions.md` 2026-04-07: MonthlyClose 除外](./decisions.md) 参照）

### UC-3: 領収書発行

1. 該当の宿泊実績を選び「領収書発行」をクリック
2. 宛名・備考を入力
3. PDFをダウンロード or 印刷してゲストに渡す
4. 発行者（誰が発行したか）はレコードに自動記録される

### UC-4: スタッフの追加・無効化

1. ログイン中のスタッフ（全員同権限のため誰でも可）が管理画面を開く
2. 「ユーザー追加」で新しいスタッフのメールアドレスを登録
3. 退職者は「無効化」で以後のログインを止める（過去のレコードに紐づくユーザー情報は残す）

> v0は全員同権限のため、ユーザーの追加・無効化は誰でも実行できる。
> 「管理者だけが触れる」運用が必要になったらロール導入とセットで v1以降に検討する。

#### 初期スタッフ（最初の1人目）の作成方法

初回deploy直後はDBにユーザーが0人で、画面からログインできない。1人目は以下のいずれかで作成する:

- `db:seed` で環境変数（`INITIAL_ADMIN_EMAIL` / `INITIAL_ADMIN_NAME` / `INITIAL_ADMIN_PASSWORD`）経由で初期スタッフを投入
- `bin/rails create_user EMAIL=... NAME=...` のような専用 rake タスク

技術スタック選定では `db:seed` 方式を基本線として採用済み（[`docs/tech-stack.md` §5.2](./tech-stack.md) 参照）。
2人目以降は1人目がログインしてユーザー管理画面から追加する。

---

## 4. データモデル（v0最小版）

### Stay（宿泊実績）

| カラム | 型 | 必須 | 説明 |
|---|---|---|---|
| id | string | ✓ | UUID |
| check_in_date | date | ✓ | チェックイン日 |
| nights | int | ✓ | 連泊数 |
| guest_name | string | ✓ | 代表者氏名 |
| num_guests | int | ✓ | 総宿泊人数 |
| num_taxable_guests | int | ✓ | 課税対象人数 |
| num_exempt_guests | int | ✓ | 免除人数（通常0） |
| nightly_rate | int | ✓ | 1人1泊宿泊料金（税抜） |
| taxable_amount | int | ✓ | 課税対象合計（計算結果） |
| tax_amount | int | ✓ | 宿泊税額（計算結果） |
| tax_rule_version | string | ✓ | 税計算に使用した条例 version。Stay 入力時に当時の current version を焼き付ける。例: `okinawa-2027-02-01`。v0 は単一値固定運用、切替ロジックは v1 |
| exemption_reason | string |  | 免除理由（任意） |
| channel | string |  | 予約チャネル名（Airbnb / Booking / 自社 / 直接 等） |
| external_reservation_id | string |  | チャネル側の予約ID（突合用） |
| payment_method | enum |  | 決済手段（square / cash / ota / other）。Square 前提運用の備え。v0 は手入力・API 連携は v1。紙台帳ベース運用では空欄も可（紙台帳側に対応列を持たないため）、iPad 現場入力運用では UC-1' のフローに従って入力する |
| memo | text |  | 自由メモ |
| status | enum | ✓ | active / cancelled |
| created_by_user_id | int | ✓ | 作成したスタッフ |
| updated_by_user_id | int | ✓ | 最終更新したスタッフ |
| created_at | datetime | ✓ |  |
| updated_at | datetime | ✓ |  |

**整合チェック**: `num_guests = num_taxable_guests + num_exempt_guests`

**設計メモ**:
- 1予約=1レコード。連泊は `nights` で表現（§2参照）
- 複数部屋は v0非対応。発生時は予約を分割入力
- `channel` / `external_reservation_id` は v0では入力欄を持つだけで分析機能は持たない。将来のOTA連携・突合の備え
  - チャネル名はフリーテキストではなく、設定ファイルでプリセット定義したプルダウン入力にする想定（揺らぎ防止）
- 更新者追跡の**主軸は papertrail 等の履歴 gem** とし、変更ごとに `whodunnit` で誰が変更したかをバージョンレコード側に記録する
- `created_by_user_id` / `updated_by_user_id` は **一覧表示や絞り込み時の速引き用**として Stay 本体に持つ（履歴を毎回 join しなくて済むようにするため）
- 「誰がいつ何を変更したか」の正は履歴 gem 側。Stay 本体の `updated_by_user_id` は最終更新者のキャッシュという位置付け
- 具体的な履歴 gem（papertrail / audited 等）は技術スタック選定で決定
- `tax_rule_version` は Stay 入力時に当時の current version（v0 は `okinawa-2027-02-01` 固定）を焼き付ける。マイグレーションでは NOT NULL カラムとして追加。詳細は [`docs/decisions.md` 2026-04-07: tax_rule_version](./decisions.md) 参照

### Receipt（領収書）

| カラム | 型 | 必須 | 説明 |
|---|---|---|---|
| id | string | ✓ | UUID |
| stay_id | string | ✓ | 紐付く宿泊実績 |
| issue_date | date | ✓ | 発行日 |
| recipient_name | string | ✓ | 宛名 |
| subtotal | int | ✓ | 宿泊料金（本体） |
| tax_amount | int | ✓ | 宿泊税額 |
| total | int | ✓ | 合計 |
| note | string |  | 但し書き |
| pdf_path | string |  | 生成PDFのパス |
| issued_by_user_id | int | ✓ | 発行したスタッフ |
| created_at | datetime | ✓ |  |

### MonthlyExport（月次エクスポート実行記録）

> v0 では月次「確定」概念を持たないため、エクスポート実行の事実だけを記録する。Stay の編集ロックは行わない。詳細は [`docs/decisions.md` 2026-04-07: MonthlyClose を v0 から外す](./decisions.md) 参照。

| カラム | 型 | 必須 | 説明 |
|---|---|---|---|
| id | string | ✓ | UUID |
| year_month | string | ✓ | 対象月 YYYY-MM |
| exported_at | datetime | ✓ | エクスポート実行時刻 |
| exported_by_user_id | int | ✓ | エクスポートを実行したスタッフ |
| format | enum | ✓ | csv / pdf |
| total_guests | int | ✓ | エクスポート時点での集計値（参考） |
| total_taxable_guests | int | ✓ | 同上 |
| total_taxable_amount | int | ✓ | 同上 |
| total_tax_amount | int | ✓ | 同上 |

**設計メモ**:
- エクスポートは何度でも実行可能。過去の MonthlyExport は履歴として残す
- エクスポート済の月に Stay 修正が入った場合、画面側で「この月は YYYY-MM-DD HH:MM にエクスポート済です」の警告を出すが、編集自体は許可する
- 月次の再エクスポートが必要になった場合は再度ボタンを押せばよい（新しい MonthlyExport レコードが追加される）

### User（スタッフユーザー）

| カラム | 型 | 必須 | 説明 |
|---|---|---|---|
| id | int | ✓ | 主キー |
| email | string | ✓ | ログインID。一意 |
| name | string | ✓ | 表示名 |
| password_digest | string | ✓ | パスワードハッシュ（または認証ライブラリの標準カラム） |
| active | bool | ✓ | 無効化フラグ。falseだとログイン不可 |
| created_at | datetime | ✓ |  |
| updated_at | datetime | ✓ |  |

**設計メモ**:
- ロール分けはなし（全員同権限）。将来必要になったら role カラムを追加
- `active = false` で無効化。物理削除はしない（過去レコードへの紐付けが切れるため）
- 認証ライブラリ（Devise / Rodauth 等）の標準カラム構成に合わせる想定。確定は技術スタック選定時

### 施設情報・設定の保管場所

「コードに書かない・他人が deploy しても動く」ための設定の置き場所。v0 では設定 UI を持たず、直接編集する想定。詳細な判断背景は [`docs/decisions.md` 2026-04-07: config/facility.json の概念を v0 では採用しない](./decisions.md) 参照。

#### テキスト設定: Rails credentials

`bin/rails credentials:edit` で以下の構造を編集する。`config/credentials.yml.enc` に暗号化保存され、`config/master.key` は **Kamal secrets** で本番に配布する。

```yaml
# config/credentials.yml.enc （復号後のイメージ）
facility:
  name: ○○ゲストハウス
  address: 沖縄県○○市...
  phone: 098-xxx-xxxx
  operator_name: 事業者名（届出名義）
  registration_number: 特別徴収義務者登録番号
  host_license_number: 住宅宿泊事業届出番号

tax:
  rule_id: okinawa
  # v0 は tax_rule_version 固定運用のため overrides は持たない。
  # 条例改定は app/services/tax_rules/okinawa.rb の VERSION 更新で対応する。

channels:
  - Airbnb
  - Booking.com
  - 楽天バケーションステイ
  - 自社サイト
  - 直接

receipt:
  header_lines:
    - ○○ゲストハウス
    - 沖縄県○○市...
  footer_text: ご利用ありがとうございました
  issuer_name: 発行責任者名
  registration_label: 登録番号: ...
```

#### バイナリ資産: `app/assets/images/facility/`

ロゴ画像等のバイナリ資産は以下に配置する。実体は `.gitignore` で除外し、リポジトリには配置例のみ残す（例: `app/assets/images/facility/.gitkeep` + `README`）。

```
app/assets/images/facility/
  logo.png          ← 施設ロゴ（.gitignore 対象）
  receipt_seal.png  ← 発行印等（.gitignore 対象、任意）
```

**ポイント**:
- テキスト設定は Rails 標準の credentials で暗号化管理されるため、`config/facility.json` 方式よりも秘密情報管理が安全
- バイナリは credentials に含めず assets ディレクトリに置くことで画像最適化パイプライン（Propshaft）に載る
- 汎用配布（他事業者へのインストール）時の受け渡し手順は v1 で改めて検討する（初期セットアップ wizard / Volume マウント等）

---

## 5. 画面構成（v0）

全画面は **Mac / Windows / Linux の各モダンブラウザ** に加え、**iPad Safari でも破綻なく操作できる**ことを v0 要件とする。レスポンシブ対応は Hotwire + Tailwind の標準機能で達成する想定。ただしスマートフォン縦画面の最適化は v0 スコープ外（iPad 以上の画面サイズを保証範囲とする）。

1. **ログイン画面** — メール + パスワード（v0確定。Magic Link等の他方式は将来検討）
2. **ホーム** — 今月のサマリーカード（宿泊数・税額）と直近入力ショートカット
3. **宿泊実績一覧** — 月切替 + 行クリックで編集
4. **宿泊実績入力フォーム** — 新規・編集兼用
5. **月次集計画面** — 月別の合計表示、エクスポート実行履歴（MonthlyExport）の参照
6. **領収書発行画面** — 宿泊実績選択 → 宛名入力 → PDF生成
7. **エクスポート画面** — 月選択 → CSV/PDFダウンロード
8. **ユーザー管理画面** — スタッフ追加 / 無効化（v0最小機能）

施設情報・税率・領収書テンプレ等の本格設定画面は v0 ではなし（Rails credentials を `bin/rails credentials:edit` で直接編集、ロゴ等は `app/assets/images/facility/` に直接配置）。
ユーザー管理だけは画面を持つ（複数スタッフが触るため credentials 直編集は現実的でない）。

---

## 6. 税計算ロジック（プラグイン構造）

### インターフェース

単一 Stay の計算と、月次集計（期間 + Stay 一覧 → 集計結果）の2つを Ruby の Service Object として定義する。

```ruby
# app/services/tax_rules/base.rb
#
# 自治体プラグインの抽象基底クラス。
# 各自治体は本クラスを継承し、#calculate と #summarize を実装する。
module TaxRules
  class Base
    # 自治体識別子（例: "okinawa"）。サブクラスで定義
    ID = nil
    # 表示ラベル（例: "沖縄県宿泊税"）。サブクラスで定義
    LABEL = nil
    # 条例 version（例: "okinawa-2027-02-01"）。条例改定時に新しい値を発行する。
    # 命名規則: "<prefecture>-<施行日 YYYY-MM-DD>"。
    VERSION = nil

    # 単一 Stay から税額を計算する。
    #
    # @param input [Hash] :nightly_rate, :nights, :num_taxable_guests
    # @return [Hash] :taxable_amount, :tax_amount, :breakdown(計算根拠の説明文字列)
    def calculate(input)
      raise NotImplementedError
    end

    # 期間 + Stay 一覧から月次集計を返す。
    #
    # @param stays [Array<Stay>] 対象期間に含まれる Stay レコード
    # @param year_month [String] "YYYY-MM"
    # @return [Hash] :year_month, :total_guests, :total_taxable_guests,
    #                :total_taxable_amount, :total_tax_amount,
    #                :details(Array of {stay_id:, taxable_amount:, tax_amount:})
    def summarize(stays, year_month)
      raise NotImplementedError
    end
  end
end
```

**ガイドライン**:
- 新しい自治体に対応する時は `app/services/tax_rules/<prefecture>.rb` を追加し、`TaxRules::Base` を継承して `#calculate` と `#summarize` を実装する
- **`VERSION`** は条例改定時に新しい値を発行する。過去の Stay には保存時の `tax_rule_version` を残しておき、再計算時に当時のロジックを呼び出せるようにする（[`docs/decisions.md` 2026-04-07: tax_rule_version](./decisions.md) 参照）
- v0 では `tax_rule_version` の **切替ロジックは実装しない**（実質単一値固定運用）。改定が発生した v1 以降で version 解決ロジックを導入する
- `breakdown` はテキストで計算根拠を残し、領収書や監査時に表示できるようにする

### v0実装: `app/services/tax_rules/okinawa.rb`

- 令和9年（2027年）2月1日施行の沖縄県宿泊税条例（令和8年沖縄県条例第1号）に準拠する
- v0 期間中は単一 version `okinawa-2027-02-01` を固定で使用
- **条例確定値の本格反映は別 Issue/PR で実施**（Issue #12 の A スコープ）。本 PR では値の精緻化は行わない
- v0 の暫定実装値（条例本文確定取り込み前）:
  - 税率: 100分の2 (2.0%) ※附則4項の併課区域は対象外（自社民泊は今帰仁村 = 標準スキーム適用）
  - 課税標準上限: 1人1泊あたり10万円
  - 免税点・端数処理等の詳細は条例情報取り込み PR で確定

⚠️ 実装時に税率・上限値はダミーではなく条例本文の値を埋めること。値の出典コメントを必ず残す。

---

## 7. オープンクエスチョン（v0着手前に確定したい）

### 制度・条例関連

- [ ] 沖縄県宿泊税条例の最終税率
- [ ] 施行日
- [ ] 課税標準に含む/除く要素（食事代・サービス料・清掃費）
- [ ] 免税点の有無と金額
- [ ] 修学旅行等の課税免除の運用
- [ ] 領収書に必須記載すべき項目（県の指定があるか）
- [ ] 保存期間（電帳法ベースで7年想定で進めるか）

### 業務・実務関連

- [x] ~~**決済手段の扱い**~~ — 決着済み: Square を決済端末として前提化し、Stay モデルに `payment_method` カラム（square / cash / ota / other）を持つ。v0 はスタッフ手入力、Square API 連携は v1 へ送る（[decisions.md 2026-04-08](./decisions.md) 参照）
- [ ] **端数処理ルール**:
  - 円未満の処理（切り捨て / 四捨五入 / 切り上げ）
  - 人ごとに丸めるか、合計額で丸めるか
  - 売上違算が出た時の調整方針
- [x] ~~**取消・修正の運用**~~ — 決着済み: v0 では月次「確定」概念を持たず、Stay は常時編集可。エクスポート済月の編集時は警告のみ表示し、編集自体は許可する。事後監査は paper_trail に委ねる（[`docs/decisions.md` 2026-04-07: MonthlyClose を v0 から外す](./decisions.md) 参照）

### 運用方針

- [x] ~~**条例変更への追従方針**~~ — 決着済み: 基本方針は **「`app/services/tax_rules/okinawa.rb` の更新 + `VERSION` 更新」のみで完結させる**。過去の Stay には保存時の `tax_rule_version` を残し、再計算時に当時のロジックを呼べるようにする。v0 は単一値固定運用、version 切替ロジックは v1（[`docs/decisions.md` 2026-04-07: tax_rule_version カラム追加](./decisions.md) 参照）

---

## 8. v1以降に持ち越す機能（メモ）

優先度の参考。実装順は v0完了後に再検討。

| カテゴリ | 機能 | 想定優先度 |
|---|---|---|
| 自動化 | Airbnb iCal取込 | 高 |
| 自動化 | **Square API 連携**（売上取込・Stay との突合・入力省力化） | 高 |
| 配布 | **助成金活用キット販売モデル**の具体化（キッティング手順、初期セットアップ自動化、助成金申請資料） | 高 |
| 法令対応 | 宿泊者名簿の自動生成・提出（住宅宿泊事業法） | 高 |
| 汎用化 | 多自治体対応（京都・東京・倶知安・福岡等の税ルール追加） | 高 |
| UX | 設定UI画面 | 中 |
| 多言語 | 英語/中国語/韓国語の領収書 | 中 |
| 配布 | 他オーナー向けインストーラ・テンプレ配布 | 中 |
| 認証 | Magic Link認証 | 低 |
| 監査 | 操作ログ・変更履歴の本格実装 | 低 |
| 法令対応 | 電帳法対応の本格化（タイムスタンプ等） | 低 |

---

## 関連ドキュメント

- [`docs/non-functional-requirements.md`](./non-functional-requirements.md) — 非機能要件
- [`docs/tech-stack.md`](./tech-stack.md) — 技術スタック選定
- [`docs/paper-ledger-template.md`](./paper-ledger-template.md) — 紙台帳テンプレート

実装フェーズへの次のステップは [README.md の「次のステップ」](../README.md#次のステップ) を参照。
