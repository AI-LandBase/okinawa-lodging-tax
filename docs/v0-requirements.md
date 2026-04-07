# v0 要件定義 — 民泊MVP版

> v0は「ユーザー自身の小規模民泊で日常運用できる最小機能」のスコープ。
> 将来「他の小規模宿泊事業者にも汎用的に提供できる1施設1インスタンスのアプリ」へ育てる前提。
> 既存の [`requirements.md`](./requirements.md) は SaaS拡張時に参照する将来要件として残す。

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

施設名・住所・電話番号・登録番号・ロゴ等はすべて `config/facility.json` から読む。
他人が deploy する時はこのファイルを書き換えるだけで動くこと。

### 規律2: 税ロジックを自治体ごとに分離

```
src/tax-rules/
  okinawa.ts      ← 沖縄県宿泊税
  index.ts        ← 設定で切替（v0はokinawa固定）
```

各ルールは共通インターフェース `calculate(input): TaxResult` を実装。
将来 `kyoto.ts` `tokyo.ts` を追加するだけで他自治体対応が可能。

### 規律3: 領収書・帳票はテンプレート化

ロゴ・住所・但し書きをコードに直書きせず、テンプレート + 設定で差し替え可能にする。

---

## 2. スコープ

### v0でやること

| # | 機能 | 内容 |
|---|---|---|
| 1 | 宿泊実績の手入力 | 紙台帳から1件ずつ転記する想定の単純フォーム |
| 2 | 宿泊税の自動計算 | 入力値から税額を計算してレコードに保存 |
| 3 | 月次集計 | 当月の人数・料金・税額の合計を表示 |
| 4 | 領収書PDF出力 | 1宿泊1枚。宿泊料金と宿泊税を分離表示 |
| 5 | 月次データのエクスポート | 申告書転記用のCSV/PDF |

### v0でやらないこと（明示）

- ❌ 認証・ユーザー管理（自分しか触らない）
- ❌ Web UI上での設定変更画面（設定ファイル直編集でOK）
- ❌ 自治体マスタのDB管理（コード内分岐で十分）
- ❌ OTA連携・iCal取込（v1以降）
- ❌ 宿泊者名簿の自動生成・提出（v1以降）
- ❌ マルチ施設対応・マルチユーザー対応
- ❌ 監査ログの本格実装
- ❌ 電帳法対応の本格化（最低限の保存のみ）

---

## 3. 想定ユースケース

### UC-1: 当日分の宿泊実績入力

1. オーナーが朝/夕にPCを開き、紙台帳を見ながら直近のチェックイン分を入力
2. フォームに日付・人数・料金・代表者名等を入力
3. 保存ボタンで税額が自動計算され、一覧に追加される

### UC-2: 月次の申告準備

1. 月初に「月次集計画面」で前月分の合計を確認
2. 「月次確定」ボタンで対象月を編集ロック
3. 「エクスポート」から申告書転記用のCSV/PDFをダウンロード
4. 紙の申告書に転記して県へ提出

### UC-3: 領収書発行

1. 該当の宿泊実績を選び「領収書発行」をクリック
2. 宛名・備考を入力
3. PDFをダウンロード or 印刷してゲストに渡す

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
| exemption_reason | string |  | 免除理由（任意） |
| memo | text |  | 自由メモ |
| status | enum | ✓ | active / cancelled |
| created_at | datetime | ✓ |  |
| updated_at | datetime | ✓ |  |

整合チェック: `num_guests = num_taxable_guests + num_exempt_guests`

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
| created_at | datetime | ✓ |  |

### MonthlyClose（月次締め）

| カラム | 型 | 必須 | 説明 |
|---|---|---|---|
| id | string | ✓ | UUID |
| year_month | string | ✓ | YYYY-MM |
| closed_at | datetime | ✓ | 確定日時 |
| total_guests | int | ✓ |  |
| total_taxable_guests | int | ✓ |  |
| total_taxable_amount | int | ✓ |  |
| total_tax_amount | int | ✓ |  |

### config/facility.json（施設情報・コミット対象外）

```json
{
  "name": "施設名",
  "address": "沖縄県...",
  "phone": "098-...",
  "registration_number": "特別徴収義務者番号",
  "tax_rule_id": "okinawa",
  "receipt": {
    "logo_path": "config/logo.png",
    "footer_text": "ご利用ありがとうございました"
  }
}
```

`config/facility.example.json` をリポジトリに置き、実体は `.gitignore` で除外する。

---

## 5. 画面構成（v0）

1. **ホーム** — 今月のサマリーカード（宿泊数・税額）と直近入力ショートカット
2. **宿泊実績一覧** — 月切替 + 行クリックで編集
3. **宿泊実績入力フォーム** — 新規・編集兼用
4. **月次集計画面** — 月別の確定状況と合計、確定ボタン
5. **領収書発行画面** — 宿泊実績選択 → 宛名入力 → PDF生成
6. **エクスポート画面** — 月選択 → CSV/PDFダウンロード

設定画面はv0ではなし（`config/facility.json` を直接編集）。

---

## 6. 税計算ロジック（プラグイン構造）

### インターフェース

```ts
// src/tax-rules/types.ts
type TaxCalcInput = {
  nightlyRate: number;       // 1人1泊宿泊料金
  nights: number;            // 連泊数
  numTaxableGuests: number;  // 課税対象人数
};

type TaxCalcResult = {
  taxableAmount: number;     // 課税対象合計
  taxAmount: number;         // 宿泊税額
  breakdown: string;         // 計算根拠（監査用）
};

interface TaxRule {
  id: string;
  label: string;
  calculate(input: TaxCalcInput): TaxCalcResult;
}
```

### v0実装: `src/tax-rules/okinawa.ts`

- 沖縄県宿泊税条例の**最終確定値が未定**のため、暫定値で実装
- 条例確定後はこのファイルのみ更新すれば全機能に反映される
- 暫定の前提:
  - 税率: 2.0% （要確定）
  - 課税標準上限: 1人1泊あたり10万円 （要確定）
  - 税額上限: 2,000円/人泊 （要確定）
  - 免税点: 未設定 （要確定）

⚠️ 実装時に「**この値はダミーです**」のコメントを残し、`docs/open-questions.md` の確定待ち事項とリンクする。

---

## 7. オープンクエスチョン（v0着手前に確定したい）

- [ ] 沖縄県宿泊税条例の最終税率
- [ ] 施行日
- [ ] 課税標準に含む/除く要素（食事代・サービス料・清掃費）
- [ ] 免税点の有無と金額
- [ ] 修学旅行等の課税免除の運用
- [ ] 領収書に必須記載すべき項目（県の指定があるか）
- [ ] 保存期間（電帳法ベースで7年想定で進めるか）

---

## 8. v1以降に持ち越す機能（メモ）

優先度の参考。実装順は v0完了後に再検討。

| カテゴリ | 機能 | 想定優先度 |
|---|---|---|
| 自動化 | Airbnb iCal取込 | 高 |
| 法令対応 | 宿泊者名簿の自動生成・提出（住宅宿泊事業法） | 高 |
| 汎用化 | 多自治体対応（京都・東京・倶知安・福岡等の税ルール追加） | 高 |
| UX | 設定UI画面 | 中 |
| 多言語 | 英語/中国語/韓国語の領収書 | 中 |
| 配布 | 他オーナー向けインストーラ・テンプレ配布 | 中 |
| 認証 | Magic Link認証 | 低 |
| 監査 | 操作ログ・変更履歴の本格実装 | 低 |
| 法令対応 | 電帳法対応の本格化（タイムスタンプ等） | 低 |

---

## 次のドキュメント

- [ ] `docs/paper-ledger-template.md` — 紙台帳テンプレ（システム入力欄と1:1対応で設計）
- [ ] 技術スタック選定（要件確定後）
