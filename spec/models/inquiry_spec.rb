require "rails_helper"

RSpec.describe Inquiry, type: :model do
  describe "バリデーション" do
    it "必須カラムが揃っていれば有効" do
      inquiry = build(:inquiry)
      expect(inquiry).to be_valid
    end

    it "facility_name がなければ無効" do
      inquiry = build(:inquiry, facility_name: "")
      expect(inquiry).not_to be_valid
    end

    it "contact_name がなければ無効" do
      inquiry = build(:inquiry, contact_name: "")
      expect(inquiry).not_to be_valid
    end

    it "email がなければ無効" do
      inquiry = build(:inquiry, email: "")
      expect(inquiry).not_to be_valid
    end

    it "email の形式が不正なら無効" do
      inquiry = build(:inquiry, email: "invalid")
      expect(inquiry).not_to be_valid
    end

    it "必須項目のみで有効（任意項目は空でもOK）" do
      inquiry = build(:inquiry, phone: nil, facility_type: nil, has_pc: nil, message: nil)
      expect(inquiry).to be_valid
    end

    it "facility_type が不正な値なら無効" do
      inquiry = build(:inquiry, facility_type: "invalid")
      expect(inquiry).not_to be_valid
    end

    it "has_pc が不正な値なら無効" do
      inquiry = build(:inquiry, has_pc: "invalid")
      expect(inquiry).not_to be_valid
    end

    it "facility_type が空文字なら有効" do
      inquiry = build(:inquiry, facility_type: "")
      expect(inquiry).to be_valid
    end

    it "has_pc が空文字なら有効" do
      inquiry = build(:inquiry, has_pc: "")
      expect(inquiry).to be_valid
    end
  end

  describe "ラベルメソッド" do
    it "#facility_type_label が日本語ラベルを返す" do
      inquiry = build(:inquiry, facility_type: "minpaku")
      expect(inquiry.facility_type_label).to eq("民泊（住宅宿泊事業）")
    end

    it "#has_pc_label が日本語ラベルを返す" do
      inquiry = build(:inquiry, has_pc: "mac")
      expect(inquiry.has_pc_label).to eq("はい（Mac）")
    end
  end
end
