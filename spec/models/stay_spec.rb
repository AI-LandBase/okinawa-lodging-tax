require "rails_helper"

RSpec.describe Stay, type: :model do
  describe "バリデーション" do
    it "必須カラムが揃っていれば有効" do
      stay = build(:stay)
      expect(stay).to be_valid
    end

    it "guest_name がなければ無効" do
      stay = build(:stay, guest_name: "")
      expect(stay).not_to be_valid
    end

    it "nights が 0 なら無効" do
      stay = build(:stay, nights: 0)
      expect(stay).not_to be_valid
    end

    it "num_guests が人数合計と不一致なら無効" do
      stay = build(:stay, num_guests: 3, num_taxable_guests: 2, num_exempt_guests: 0)
      expect(stay).not_to be_valid
      expect(stay.errors[:num_guests]).to be_present
    end

    it "num_guests が人数合計と一致すれば有効" do
      stay = build(:stay, num_guests: 3, num_taxable_guests: 2, num_exempt_guests: 1)
      expect(stay).to be_valid
    end
  end

  describe "税額自動計算" do
    it "保存前に taxable_amount と tax_amount が自動計算される" do
      stay = create(:stay, nightly_rate: 8_000, nights: 2, num_guests: 3, num_taxable_guests: 3, num_exempt_guests: 0)
      expect(stay.taxable_amount).to eq(48_000)
      expect(stay.tax_amount).to eq(960)
    end

    it "tax_rule_version が自動設定される" do
      stay = create(:stay)
      expect(stay.tax_rule_version).to eq("okinawa-2027-02-01")
    end
  end

  describe "#cancel!" do
    it "status を cancelled に変更する" do
      stay = create(:stay)
      stay.cancel!
      expect(stay.reload).to be_cancelled
    end
  end

  describe "scope .for_month" do
    let(:user) { create(:user) }

    it "指定月の Stay のみ返す" do
      april_stay = create(:stay, check_in_date: Date.new(2027, 4, 15), created_by_user: user, updated_by_user: user)
      march_stay = create(:stay, check_in_date: Date.new(2027, 3, 20), created_by_user: user, updated_by_user: user)

      result = Stay.for_month(2027, 4)
      expect(result).to include(april_stay)
      expect(result).not_to include(march_stay)
    end
  end

  describe "paper_trail" do
    it "変更履歴が記録される" do
      stay = create(:stay, guest_name: "元の名前")
      stay.update!(guest_name: "新しい名前")
      expect(stay.versions.count).to eq(2)
    end
  end
end
