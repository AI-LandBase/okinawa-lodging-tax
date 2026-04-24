require "rails_helper"

RSpec.describe "SalesLeads", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /sales_leads" do
    it "営業リスト一覧を表示する" do
      get sales_leads_path
      expect(response).to have_http_status(:ok)
    end

    it "地域フィルタで絞り込める" do
      create(:sales_lead, region: "北部")
      create(:sales_lead, region: "南部")
      get sales_leads_path(region: "北部")
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /sales_leads/:id" do
    it "詳細を表示する" do
      lead = create(:sales_lead)
      get sales_lead_path(lead)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /sales_leads/new" do
    it "入力フォームを表示する" do
      get new_sales_lead_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /sales_leads" do
    let(:valid_params) do
      {
        sales_lead: {
          facility_name: "テストホテル",
          region: "北部",
          area: "名護市",
          phone: "0980-12-3456",
          segment: "民宿・ゲストハウス",
          sales_status: "未着手"
        }
      }
    end

    it "営業先を登録できる" do
      expect { post sales_leads_path, params: valid_params }.to change(SalesLead, :count).by(1)
    end

    it "登録後に一覧にリダイレクトする" do
      post sales_leads_path, params: valid_params
      expect(response).to redirect_to(sales_leads_path)
    end

    it "バリデーションエラー時は再表示する" do
      post sales_leads_path, params: { sales_lead: { facility_name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /sales_leads/:id" do
    let(:lead) { create(:sales_lead) }

    it "営業先を更新できる" do
      patch sales_lead_path(lead), params: { sales_lead: { sales_status: "成約" } }
      expect(lead.reload.sales_status).to eq("成約")
    end

    it "更新後に詳細にリダイレクトする" do
      patch sales_lead_path(lead), params: { sales_lead: { sales_status: "成約" } }
      expect(response).to redirect_to(sales_lead_path(lead))
    end
  end

  describe "未認証アクセス" do
    before { sign_out user }

    it "ログインページにリダイレクトされる" do
      get sales_leads_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
