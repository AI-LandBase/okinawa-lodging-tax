class Inquiry < ApplicationRecord
  FACILITY_TYPES = %w[minpaku simple_lodging ryokan hotel other].freeze
  HAS_PC_OPTIONS = %w[mac windows other_pc no].freeze

  FACILITY_TYPE_LABELS = {
    "minpaku" => "民泊（住宅宿泊事業）",
    "simple_lodging" => "簡易宿所",
    "ryokan" => "旅館",
    "hotel" => "ホテル",
    "other" => "その他"
  }.freeze

  HAS_PC_LABELS = {
    "mac" => "はい（Mac）",
    "windows" => "はい（Windows）",
    "other_pc" => "はい（その他）",
    "no" => "いいえ"
  }.freeze

  validates :facility_name, presence: true
  validates :contact_name, presence: true
  validates :email, presence: true, format: { with: /\A[^@\s]+@[^@\s]+\z/ }
  validates :facility_type, inclusion: { in: FACILITY_TYPES }, allow_blank: true
  validates :has_pc, inclusion: { in: HAS_PC_OPTIONS }, allow_blank: true

  def facility_type_label
    FACILITY_TYPE_LABELS[facility_type]
  end

  def has_pc_label
    HAS_PC_LABELS[has_pc]
  end
end
