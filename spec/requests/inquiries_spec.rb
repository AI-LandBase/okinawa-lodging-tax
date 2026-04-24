require "rails_helper"

RSpec.describe "Inquiries", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /inquiries" do
    it "お問い合わせ一覧を表示する" do
      create(:inquiry)
      get inquiries_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /inquiries/:id" do
    it "お問い合わせ詳細を表示する" do
      inquiry = create(:inquiry)
      get inquiry_path(inquiry)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "未認証アクセス" do
    before { sign_out user }

    it "一覧がログインページにリダイレクトされる" do
      get inquiries_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it "詳細がログインページにリダイレクトされる" do
      inquiry = create(:inquiry)
      get inquiry_path(inquiry)
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
