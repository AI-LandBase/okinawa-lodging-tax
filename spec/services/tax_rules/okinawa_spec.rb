require "rails_helper"

RSpec.describe TaxRules::Okinawa do
  subject(:calculator) { described_class.new }

  describe "定数" do
    it "ID は okinawa" do
      expect(described_class::ID).to eq("okinawa")
    end

    it "VERSION は okinawa-2027-02-01" do
      expect(described_class::VERSION).to eq("okinawa-2027-02-01")
    end

    it "税率は 2%" do
      expect(described_class::TAX_RATE).to eq(0.02)
    end

    it "課税標準上限は 100,000 円" do
      expect(described_class::TAXABLE_CAP).to eq(100_000)
    end
  end

  describe "#calculate" do
    context "通常ケース: 8,000円/人泊 × 2泊 × 3人" do
      let(:result) { calculator.calculate(nightly_rate: 8_000, nights: 2, num_taxable_guests: 3) }

      it "課税対象合計 = 8,000 × 2 × 3 = 48,000" do
        expect(result[:taxable_amount]).to eq(48_000)
      end

      it "税額 = floor(8,000 × 0.02) × 2 × 3 = 160 × 6 = 960" do
        expect(result[:tax_amount]).to eq(960)
      end

      it "breakdown に計算根拠が含まれる" do
        expect(result[:breakdown]).to include("8000円/人泊")
        expect(result[:breakdown]).to include("960円")
      end
    end

    context "上限超過: 150,000円/人泊 × 1泊 × 1人" do
      let(:result) { calculator.calculate(nightly_rate: 150_000, nights: 1, num_taxable_guests: 1) }

      it "課税標準は上限 100,000 円で打ち止め" do
        expect(result[:taxable_amount]).to eq(100_000)
      end

      it "税額 = floor(100,000 × 0.02) × 1 × 1 = 2,000" do
        expect(result[:tax_amount]).to eq(2_000)
      end
    end

    context "上限ちょうど: 100,000円/人泊" do
      let(:result) { calculator.calculate(nightly_rate: 100_000, nights: 1, num_taxable_guests: 1) }

      it "課税標準 = 100,000" do
        expect(result[:taxable_amount]).to eq(100_000)
      end

      it "税額 = 2,000" do
        expect(result[:tax_amount]).to eq(2_000)
      end
    end

    context "端数発生: 3,333円/人泊" do
      let(:result) { calculator.calculate(nightly_rate: 3_333, nights: 1, num_taxable_guests: 1) }

      it "税額 = floor(3,333 × 0.02) = floor(66.66) = 66" do
        expect(result[:tax_amount]).to eq(66)
      end
    end

    context "免除人数あり（課税対象0人）" do
      let(:result) { calculator.calculate(nightly_rate: 10_000, nights: 1, num_taxable_guests: 0) }

      it "税額 = 0" do
        expect(result[:tax_amount]).to eq(0)
      end

      it "課税対象合計 = 0" do
        expect(result[:taxable_amount]).to eq(0)
      end
    end

    context "連泊: 5,000円/人泊 × 7泊 × 2人" do
      let(:result) { calculator.calculate(nightly_rate: 5_000, nights: 7, num_taxable_guests: 2) }

      it "課税対象合計 = 5,000 × 7 × 2 = 70,000" do
        expect(result[:taxable_amount]).to eq(70_000)
      end

      it "税額 = floor(5,000 × 0.02) × 7 × 2 = 100 × 14 = 1,400" do
        expect(result[:tax_amount]).to eq(1_400)
      end
    end

    context "最小ケース: 1円/人泊 × 1泊 × 1人" do
      let(:result) { calculator.calculate(nightly_rate: 1, nights: 1, num_taxable_guests: 1) }

      it "税額 = floor(1 × 0.02) = floor(0.02) = 0" do
        expect(result[:tax_amount]).to eq(0)
      end
    end
  end

  describe "#summarize" do
    it "Stay 一覧から月次集計を返す" do
      stays = [
        double(id: 1, num_guests: 3, num_taxable_guests: 3, taxable_amount: 48_000, tax_amount: 960),
        double(id: 2, num_guests: 2, num_taxable_guests: 2, taxable_amount: 20_000, tax_amount: 400)
      ]

      result = calculator.summarize(stays, "2027-03")

      expect(result[:year_month]).to eq("2027-03")
      expect(result[:total_guests]).to eq(5)
      expect(result[:total_taxable_guests]).to eq(5)
      expect(result[:total_taxable_amount]).to eq(68_000)
      expect(result[:total_tax_amount]).to eq(1_360)
      expect(result[:details].size).to eq(2)
    end
  end
end
