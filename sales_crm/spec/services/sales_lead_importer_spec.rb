require "rails_helper"
require "csv"

RSpec.describe SalesLeadImporter do
  def create_csv(filename, headers:, rows:)
    path = Rails.root.join("tmp", filename)
    CSV.open(path, "w") do |csv|
      csv << headers
      rows.each { |row| csv << row }
    end
    path.to_s
  end

  after do
    FileUtils.rm_f(Dir.glob(Rails.root.join("tmp", "test_import_*.csv")))
  end

  describe "#import（南部・北部ファイル）" do
    let(:file_path) do
      create_csv(
        "test_import_south.csv",
        headers: %w[施設名 電話番号 エリア グループ ソース URL 重複候補],
        rows: [
          [ "ホテルA", "098-123-4567", "那覇市", "大型ホテル・リゾート", "OAH_那覇", "https://example.com", "" ],
          [ "ホテルB", "098-234-5678", "浦添市", "民宿・ゲストハウス", "Mapion", "https://example2.com", "重複" ]
        ]
      )
    end

    it "CSVからインポートできる" do
      result = described_class.new(file_path, region_key: "south").import
      expect(result.created).to eq(2)
      expect(result.errors).to be_empty
    end

    it "施設情報が正しく保存される" do
      described_class.new(file_path, region_key: "south").import
      lead = SalesLead.find_by(facility_name: "ホテルA")
      expect(lead.region).to eq("南部")
      expect(lead.area).to eq("那覇市")
      expect(lead.phone).to eq("098-123-4567")
      expect(lead.source).to eq("OAH_那覇")
    end

    it "重複候補フラグが設定される" do
      described_class.new(file_path, region_key: "south").import
      lead_b = SalesLead.find_by(facility_name: "ホテルB")
      expect(lead_b.duplicate_flag).to be true
    end
  end

  describe "冪等性" do
    let(:file_path) do
      create_csv(
        "test_import_idempotent.csv",
        headers: %w[施設名 電話番号 エリア],
        rows: [ [ "テストホテル", "098-111-2222", "名護市" ] ]
      )
    end

    it "同じファイルを2回実行しても重複しない" do
      described_class.new(file_path, region_key: "north").import
      result = described_class.new(file_path, region_key: "north").import

      expect(SalesLead.where(facility_name: "テストホテル").count).to eq(1)
      expect(result.created).to eq(0)
      expect(result.updated).to eq(1)
    end
  end

  describe "中部ファイル（営業管理カラム付き）" do
    let(:file_path) do
      create_csv(
        "test_import_chubu.csv",
        headers: %w[施設名 電話番号 市町村 セグメント名 優先度 IT化度 営業ステータス 担当者 提案金額],
        rows: [ [ "リゾートC", "098-333-4444", "読谷村", "大型ホテル・リゾート", "高", "中", "アポ取得", "田中", "190万円" ] ]
      )
    end

    it "営業管理カラムがインポートされる" do
      described_class.new(file_path, region_key: "chubu").import
      lead = SalesLead.find_by(facility_name: "リゾートC")

      expect(lead.region).to eq("中部")
      expect(lead.priority).to eq("高")
      expect(lead.it_literacy).to eq("中")
      expect(lead.sales_status).to eq("アポ取得")
      expect(lead.person_in_charge).to eq("田中")
      expect(lead.proposal_amount).to eq(1_900_000)
    end
  end

  describe "空行スキップ" do
    let(:file_path) do
      create_csv(
        "test_import_empty.csv",
        headers: %w[施設名 電話番号],
        rows: [ [ "", "098-000-0000" ], [ "有効なホテル", "098-111-0000" ] ]
      )
    end

    it "施設名が空の行はスキップされる" do
      result = described_class.new(file_path, region_key: "north").import
      expect(result.skipped).to eq(1)
      expect(result.created).to eq(1)
    end
  end

  describe "parse_amount" do
    let(:file_path) do
      create_csv(
        "test_import_amount.csv",
        headers: %w[施設名 電話番号 市町村 セグメント名 提案金額],
        rows: [
          [ "ホテルX", "098-001-0001", "那覇市", "その他", "200万円" ],
          [ "ホテルY", "098-001-0002", "那覇市", "その他", "1500000" ]
        ]
      )
    end

    it "'万円' 表記を整数に変換する" do
      described_class.new(file_path, region_key: "chubu").import
      expect(SalesLead.find_by(facility_name: "ホテルX").proposal_amount).to eq(2_000_000)
      expect(SalesLead.find_by(facility_name: "ホテルY").proposal_amount).to eq(1_500_000)
    end
  end

  describe "不正な region_key" do
    it "ArgumentError を発生させる" do
      expect { described_class.new("dummy.csv", region_key: "east") }.to raise_error(ArgumentError)
    end
  end
end
