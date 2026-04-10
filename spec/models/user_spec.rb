require "rails_helper"

RSpec.describe User, type: :model do
  describe "バリデーション" do
    it "name, email, password があれば有効" do
      user = build(:user)
      expect(user).to be_valid
    end

    it "name がなければ無効" do
      user = build(:user, name: "")
      expect(user).not_to be_valid
    end

    it "email がなければ無効" do
      user = build(:user, email: "")
      expect(user).not_to be_valid
    end

    it "email が重複していれば無効" do
      create(:user, email: "test@example.com")
      user = build(:user, email: "test@example.com")
      expect(user).not_to be_valid
    end
  end

  describe "#active_for_authentication?" do
    it "active が true ならログイン可能" do
      user = build(:user, active: true)
      expect(user.active_for_authentication?).to be true
    end

    it "active が false ならログイン不可" do
      user = build(:user, active: false)
      expect(user.active_for_authentication?).to be false
    end
  end

  describe "paper_trail" do
    it "変更履歴が記録される" do
      user = create(:user, name: "元の名前")
      user.update!(name: "新しい名前")
      expect(user.versions.count).to eq(2)
    end
  end
end
