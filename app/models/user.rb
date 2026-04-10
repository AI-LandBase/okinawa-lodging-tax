class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  has_paper_trail

  validates :name, presence: true

  # active == false のユーザーはログインできない
  def active_for_authentication?
    super && active?
  end

  def inactive_message
    active? ? super : :account_inactive
  end
end
