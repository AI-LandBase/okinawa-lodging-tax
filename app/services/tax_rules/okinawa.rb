# 沖縄県宿泊税の税額計算サービス。
#
# 令和8年沖縄県条例第1号「沖縄県宿泊税条例」および同施行規則（沖縄県規則第2号）に準拠。
# 施行日: 2027-02-01
#
# 本クラスは沖縄県標準スキーム（併課区域を除く）のみを実装する。
# 附則第4項の併課区域用税率（100分の0.8）は v0 スコープ外。
module TaxRules
  class Okinawa < Base
    ID      = "okinawa"
    LABEL   = "沖縄県宿泊税"
    VERSION = "okinawa-2027-02-01"

    # 税率 2%（条例第6条）
    TAX_RATE = 0.02

    # 課税標準上限 100,000 円/人泊（条例第5条）
    TAXABLE_CAP = 100_000

    # 単一 Stay から税額を計算する。
    #
    # 計算式（条例第5条・第6条準拠）:
    #   per_person_per_night_taxable = min(nightly_rate, 100_000)
    #   per_person_per_night_tax     = floor(per_person_per_night_taxable * 0.02)
    #   taxable_amount = per_person_per_night_taxable * nights * num_taxable_guests
    #   tax_amount     = per_person_per_night_tax     * nights * num_taxable_guests
    #
    # 端数処理: 1円未満切捨（地方税法通則の慣例。条例第6条に明示規定なし）
    #
    # @param input [Hash] :nightly_rate (Integer), :nights (Integer), :num_taxable_guests (Integer)
    # @return [Hash] :taxable_amount, :tax_amount, :breakdown
    def calculate(input)
      nightly_rate       = input.fetch(:nightly_rate)
      nights             = input.fetch(:nights)
      num_taxable_guests = input.fetch(:num_taxable_guests)

      # 条例第5条: 課税標準は1人1泊あたりの宿泊料金、上限10万円
      per_person_per_night_taxable = [ nightly_rate, TAXABLE_CAP ].min

      # 条例第6条: 税額 = 課税標準 × 税率（2%）、1円未満切捨
      per_person_per_night_tax = (per_person_per_night_taxable * TAX_RATE).floor

      taxable_amount = per_person_per_night_taxable * nights * num_taxable_guests
      tax_amount     = per_person_per_night_tax * nights * num_taxable_guests

      breakdown = "#{per_person_per_night_taxable}円/人泊 × #{TAX_RATE * 100}% = #{per_person_per_night_tax}円/人泊 × #{nights}泊 × #{num_taxable_guests}人 = #{tax_amount}円"

      { taxable_amount: taxable_amount, tax_amount: tax_amount, breakdown: breakdown }
    end

    # 期間 + Stay 一覧から月次集計を返す。
    #
    # @param stays [Array<Stay>] 対象期間の Stay レコード（status: active のみ渡す想定）
    # @param year_month [String] "YYYY-MM"
    # @return [Hash]
    def summarize(stays, year_month)
      details = stays.map do |stay|
        { stay_id: stay.id, taxable_amount: stay.taxable_amount, tax_amount: stay.tax_amount }
      end

      {
        year_month: year_month,
        total_guests: stays.sum(&:num_guests),
        total_taxable_guests: stays.sum(&:num_taxable_guests),
        total_taxable_amount: stays.sum(&:taxable_amount),
        total_tax_amount: stays.sum(&:tax_amount),
        details: details
      }
    end
  end
end
