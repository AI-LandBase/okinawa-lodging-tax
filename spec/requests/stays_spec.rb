require "rails_helper"

RSpec.describe "Stays", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /stays" do
    it "宿泊実績一覧を表示する" do
      get stays_path
      expect(response).to have_http_status(:ok)
    end

    it "月パラメータで絞り込める" do
      get stays_path(year: 2027, month: 4)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /stays/new" do
    it "入力フォームを表示する" do
      get new_stay_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /stays" do
    let(:valid_params) do
      {
        stay: {
          check_in_date: "2027-04-01", nights: 2, guest_name: "山田 太郎",
          num_guests: 3, num_taxable_guests: 3, num_exempt_guests: 0,
          nightly_rate: 8_000, channel: "Airbnb"
        }
      }
    end

    it "宿泊実績を登録できる" do
      expect { post stays_path, params: valid_params }.to change(Stay, :count).by(1)
      stay = Stay.last
      expect(stay.tax_amount).to eq(960)
      expect(stay.created_by_user).to eq(user)
    end

    it "バリデーションエラー時は再表示する" do
      post stays_path, params: { stay: { guest_name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /stays/:id/cancel" do
    it "宿泊実績を取り消せる" do
      stay = create(:stay, created_by_user: user, updated_by_user: user)
      patch cancel_stay_path(stay)
      expect(stay.reload).to be_cancelled
    end
  end

  describe "未認証アクセス" do
    before { sign_out user }

    it "ログインページにリダイレクトされる" do
      get stays_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
