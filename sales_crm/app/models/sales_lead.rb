class SalesLead < ApplicationRecord
  SEGMENTS = %w[大型ホテル・リゾート 中規模ビジネスホテル ペンション・コンドミニアム 民宿・ゲストハウス ペンション・貸別荘 その他].freeze
  REGIONS = %w[北部 中部 南部].freeze
  PRIORITIES = %w[最高 高 中 低].freeze
  IT_LITERACIES = %w[高 中 低].freeze
  SALES_STATUSES = %w[未着手 初回接触済 アポ取得 訪問済 提案済 成約 失注].freeze
  SUBSIDY_STATUSES = %w[未申請 申請中 承認済 不採択].freeze

  validates :facility_name, presence: true
  validates :region, presence: true, inclusion: { in: REGIONS }
  validates :segment, inclusion: { in: SEGMENTS }, allow_blank: true
  validates :priority, inclusion: { in: PRIORITIES }, allow_blank: true
  validates :it_literacy, inclusion: { in: IT_LITERACIES }, allow_blank: true
  validates :sales_status, presence: true, inclusion: { in: SALES_STATUSES }
  validates :subsidy_status, inclusion: { in: SUBSIDY_STATUSES }, allow_blank: true
  validates :proposal_amount, numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true

  scope :by_region, ->(region) { where(region: region) if region.present? }
  scope :by_segment, ->(segment) { where(segment: segment) if segment.present? }
  scope :by_priority, ->(priority) { where(priority: priority) if priority.present? }
  scope :by_sales_status, ->(status) { where(sales_status: status) if status.present? }
end
