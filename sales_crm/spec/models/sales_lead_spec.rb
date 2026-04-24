require "rails_helper"

RSpec.describe SalesLead, type: :model do
  describe "バリデーション" do
    it "必須カラムが揃っていれば有効" do
      lead = build(:sales_lead)
      expect(lead).to be_valid
    end

    it "facility_name がなければ無効" do
      lead = build(:sales_lead, facility_name: "")
      expect(lead).not_to be_valid
    end

    it "region がなければ無効" do
      lead = build(:sales_lead, region: "")
      expect(lead).not_to be_valid
    end

    it "region が定義外の値なら無効" do
      lead = build(:sales_lead, region: "東部")
      expect(lead).not_to be_valid
    end

    it "sales_status が定義外の値なら無効" do
      lead = build(:sales_lead, sales_status: "不明")
      expect(lead).not_to be_valid
    end

    it "segment が定義外の値なら無効" do
      lead = build(:sales_lead, segment: "不明なセグメント")
      expect(lead).not_to be_valid
    end

    it "segment が空なら有効" do
      lead = build(:sales_lead, segment: nil)
      expect(lead).to be_valid
    end

    it "proposal_amount が負数なら無効" do
      lead = build(:sales_lead, proposal_amount: -1)
      expect(lead).not_to be_valid
    end

    it "proposal_amount が nil なら有効" do
      lead = build(:sales_lead, proposal_amount: nil)
      expect(lead).to be_valid
    end
  end

  describe "スコープ" do
    let!(:north_lead) { create(:sales_lead, region: "北部") }
    let!(:south_lead) { create(:sales_lead, region: "南部") }

    it ".by_region で地域を絞り込める" do
      expect(SalesLead.by_region("北部")).to include(north_lead)
      expect(SalesLead.by_region("北部")).not_to include(south_lead)
    end

    it ".by_region が空なら全件返す" do
      expect(SalesLead.by_region("")).to include(north_lead, south_lead)
    end

    it ".by_sales_status でステータスを絞り込める" do
      lead = create(:sales_lead, sales_status: "成約")
      expect(SalesLead.by_sales_status("成約")).to include(lead)
      expect(SalesLead.by_sales_status("成約")).not_to include(north_lead)
    end
  end

  describe "デフォルト値" do
    it "sales_status のデフォルトは '未着手'" do
      lead = SalesLead.new
      expect(lead.sales_status).to eq("未着手")
    end

    it "duplicate_flag のデフォルトは false" do
      lead = SalesLead.new
      expect(lead.duplicate_flag).to be false
    end
  end
end
