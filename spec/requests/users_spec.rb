require "rails_helper"

RSpec.describe "Users", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /users" do
    it "ユーザー一覧を表示する" do
      get users_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /users/new" do
    it "ユーザー追加フォームを表示する" do
      get new_user_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /users" do
    it "ユーザーを追加できる" do
      expect {
        post users_path, params: { user: { name: "新スタッフ", email: "new@example.com", password: "password123", password_confirmation: "password123" } }
      }.to change(User, :count).by(1)
      expect(response).to redirect_to(users_path)
    end

    it "バリデーションエラー時は再表示する" do
      post users_path, params: { user: { name: "", email: "", password: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /users/:id/toggle_active" do
    it "ユーザーを無効化できる" do
      target = create(:user, active: true)
      patch toggle_active_user_path(target)
      expect(target.reload.active?).to be false
    end

    it "ユーザーを有効化できる" do
      target = create(:user, active: false)
      patch toggle_active_user_path(target)
      expect(target.reload.active?).to be true
    end
  end

  describe "未認証アクセス" do
    before { sign_out user }

    it "ログインページにリダイレクトされる" do
      get users_path
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
