module Api
  class InquiriesController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_action :authenticate_user!

    def create
      inquiry = Inquiry.new(inquiry_params)

      if inquiry.save
        render json: { message: "お問い合わせありがとうございます。内容を確認の上、ご連絡いたします。" }, status: :created
      else
        render json: { errors: inquiry.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def inquiry_params
      params.require(:inquiry).permit(
        :facility_name, :contact_name, :email, :phone,
        :facility_type, :has_pc, :message
      )
    end
  end
end
