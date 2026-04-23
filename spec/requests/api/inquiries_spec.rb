require "rails_helper"

RSpec.describe "Api::Inquiries", type: :request do
  describe "POST /api/inquiries" do
    let(:valid_params) do
      {
        inquiry: {
          facility_name: "テスト民泊",
          contact_name: "山田 太郎",
          email: "test@example.com",
          phone: "098-123-4567",
          facility_type: "minpaku",
          has_pc: "mac",
          message: "導入について相談したいです"
        }
      }
    end

    it "問い合わせを作成できる" do
      expect {
        post api_inquiries_path, params: valid_params, as: :json
      }.to change(Inquiry, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["message"]).to be_present
    end

    it "必須項目のみで作成できる" do
      params = { inquiry: { facility_name: "テスト", contact_name: "太郎", email: "test@example.com" } }
      expect {
        post api_inquiries_path, params: params, as: :json
      }.to change(Inquiry, :count).by(1)

      expect(response).to have_http_status(:created)
    end

    it "バリデーションエラー時は422を返す" do
      params = { inquiry: { facility_name: "", contact_name: "", email: "" } }
      expect {
        post api_inquiries_path, params: params, as: :json
      }.not_to change(Inquiry, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["errors"]).to be_present
    end

    it "認証なしでアクセスできる" do
      post api_inquiries_path, params: valid_params, as: :json
      expect(response).to have_http_status(:created)
    end
  end
end
