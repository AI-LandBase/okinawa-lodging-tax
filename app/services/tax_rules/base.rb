# 自治体プラグインの抽象基底クラス。
# 各自治体は本クラスを継承し、#calculate と #summarize を実装する。
#
# 新しい自治体に対応する場合:
#   app/services/tax_rules/<prefecture>.rb を追加し、
#   TaxRules::Base を継承して #calculate と #summarize を実装する。
module TaxRules
  class Base
    # 自治体識別子（例: "okinawa"）。サブクラスで定義。
    ID = nil
    # 表示ラベル（例: "沖縄県宿泊税"）。サブクラスで定義。
    LABEL = nil
    # 条例 version（例: "okinawa-2027-02-01"）。条例改定時に新しい値を発行する。
    # 命名規則: "<prefecture>-<施行日 YYYY-MM-DD>"。
    VERSION = nil

    # 単一 Stay から税額を計算する。
    #
    # @param input [Hash] :nightly_rate, :nights, :num_taxable_guests
    # @return [Hash] :taxable_amount, :tax_amount, :breakdown
    def calculate(input)
      raise NotImplementedError
    end

    # 期間 + Stay 一覧から月次集計を返す。
    #
    # @param stays [Array<Stay>] 対象期間に含まれる Stay レコード
    # @param year_month [String] "YYYY-MM"
    # @return [Hash] :year_month, :total_guests, :total_taxable_guests,
    #                :total_taxable_amount, :total_tax_amount,
    #                :details(Array)
    def summarize(stays, year_month)
      raise NotImplementedError
    end
  end
end
