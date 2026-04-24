class SalesLeadsController < ApplicationController
  before_action :set_sales_lead, only: %i[show edit update]

  def index
    @sales_leads = SalesLead
                   .by_region(params[:region])
                   .by_segment(params[:segment])
                   .by_priority(params[:priority])
                   .by_sales_status(params[:sales_status])
                   .order(created_at: :desc)
  end

  def show
  end

  def new
    @sales_lead = SalesLead.new
  end

  def create
    @sales_lead = SalesLead.new(sales_lead_params)

    if @sales_lead.save
      redirect_to sales_leads_path, notice: "営業先を登録しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @sales_lead.update(sales_lead_params)
      redirect_to sales_lead_path(@sales_lead), notice: "営業先を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_sales_lead
    @sales_lead = SalesLead.find(params[:id])
  end

  def sales_lead_params
    params.require(:sales_lead).permit(
      :facility_name, :segment, :area, :phone, :region,
      :priority, :it_literacy, :sales_status, :person_in_charge,
      :contacted_at, :appointment_date, :visited_at,
      :proposal_amount, :subsidy_status, :closed_at, :monthly_start_date,
      :memo, :source, :source_url, :duplicate_flag
    )
  end
end
