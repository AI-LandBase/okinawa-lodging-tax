class StaysController < ApplicationController
  before_action :set_stay, only: %i[edit update cancel]
  before_action :set_month, only: :index

  def index
    @stays = Stay.for_month(@year, @month).order(check_in_date: :desc, created_at: :desc)
  end

  def new
    @stay = Stay.new(check_in_date: Date.current)
  end

  def create
    @stay = Stay.new(stay_params)
    @stay.created_by_user = current_user
    @stay.updated_by_user = current_user

    if @stay.save
      redirect_to stays_path(year: @stay.check_in_date.year, month: @stay.check_in_date.month),
                  notice: "宿泊実績を登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    @stay.updated_by_user = current_user
    if @stay.update(stay_params)
      redirect_to stays_path(year: @stay.check_in_date.year, month: @stay.check_in_date.month),
                  notice: "宿泊実績を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def cancel
    @stay.updated_by_user = current_user
    @stay.cancel!
    redirect_to stays_path(year: @stay.check_in_date.year, month: @stay.check_in_date.month),
                notice: "宿泊実績を取り消しました"
  end

  private

  def set_stay
    @stay = Stay.find(params[:id])
  end

  def set_month
    @year  = (params[:year]  || Date.current.year).to_i
    @month = (params[:month] || Date.current.month).to_i
  end

  def stay_params
    params.require(:stay).permit(
      :check_in_date, :nights, :guest_name,
      :num_guests, :num_taxable_guests, :num_exempt_guests,
      :nightly_rate, :exemption_reason,
      :channel, :external_reservation_id, :payment_method, :memo
    )
  end
end
