class Stay < ApplicationRecord
  has_paper_trail

  belongs_to :created_by_user, class_name: "User"
  belongs_to :updated_by_user, class_name: "User"

  enum :status, { active: "active", cancelled: "cancelled" }, default: :active
  enum :payment_method, { square: "square", cash: "cash", ota: "ota", other: "other" }, prefix: true

  validates :check_in_date, presence: true
  validates :nights, presence: true, numericality: { greater_than_or_equal_to: 1, only_integer: true }
  validates :guest_name, presence: true
  validates :num_guests, presence: true, numericality: { greater_than_or_equal_to: 1, only_integer: true }
  validates :num_taxable_guests, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :num_exempt_guests, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :nightly_rate, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :status, presence: true
  validate :guests_count_consistency

  before_validation :calculate_tax, if: :should_calculate_tax?

  scope :for_month, ->(year, month) {
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month
    where(check_in_date: start_date..end_date)
  }

  def cancel!
    update!(status: :cancelled)
  end

  private

  def guests_count_consistency
    return if num_guests.blank? || num_taxable_guests.blank? || num_exempt_guests.blank?

    if num_guests != num_taxable_guests + num_exempt_guests
      errors.add(:num_guests, "は課税対象人数と免除人数の合計と一致する必要があります")
    end
  end

  def should_calculate_tax?
    nightly_rate.present? && nights.present? && num_taxable_guests.present?
  end

  def calculate_tax
    calculator = ::TaxRules::Okinawa.new
    result = calculator.calculate(
      nightly_rate: nightly_rate,
      nights: nights,
      num_taxable_guests: num_taxable_guests
    )
    self.taxable_amount = result[:taxable_amount]
    self.tax_amount = result[:tax_amount]
    self.tax_rule_version = ::TaxRules::Okinawa::VERSION
  end
end
