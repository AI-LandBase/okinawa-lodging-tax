class UsersController < ApplicationController
  before_action :set_user, only: %i[edit update toggle_active]

  def index
    @users = User.order(:name)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to users_path, notice: "ユーザー「#{@user.name}」を追加しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(user_update_params)
      redirect_to users_path, notice: "ユーザー「#{@user.name}」を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def toggle_active
    @user.update!(active: !@user.active?)
    status = @user.active? ? "有効化" : "無効化"
    redirect_to users_path, notice: "ユーザー「#{@user.name}」を#{status}しました"
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def user_update_params
    if params[:user][:password].blank?
      params.require(:user).permit(:name, :email)
    else
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end
  end
end
