class SalesLeadImporter
  Result = Struct.new(:created, :updated, :skipped, :errors, keyword_init: true)

  REGION_MAP = {
    "north" => "北部",
    "chubu" => "中部",
    "south" => "南部"
  }.freeze

  def initialize(file_path, region_key:)
    @file_path = file_path
    @region = REGION_MAP.fetch(region_key) { raise ArgumentError, "Unknown region_key: #{region_key}. Use: #{REGION_MAP.keys.join(', ')}" }
    @region_key = region_key
  end

  def import
    result = Result.new(created: 0, updated: 0, skipped: 0, errors: [])
    spreadsheet = Roo::Spreadsheet.open(@file_path)
    sheet = pick_sheet(spreadsheet)

    headers = normalize_headers(sheet.row(1))
    (2..sheet.last_row).each do |i|
      row = Hash[headers.zip(sheet.row(i))]
      import_row(row, result, i)
    end

    result
  end

  private

  def pick_sheet(spreadsheet)
    if @region_key == "chubu"
      target = spreadsheet.sheets.find { |s| s.include?("営業管理") }
      spreadsheet.sheet(target || spreadsheet.sheets.first)
    else
      target = spreadsheet.sheets.find { |s| s.include?("Deduped") }
      spreadsheet.sheet(target || spreadsheet.sheets.first)
    end
  end

  def normalize_headers(row)
    row.map { |h| h.to_s.strip }
  end

  def import_row(row, result, row_number)
    facility_name = row.values_at(*facility_name_keys).compact.first.to_s.strip
    if facility_name.blank?
      result.skipped += 1
      return
    end

    phone = normalize_phone(row.values_at(*phone_keys).compact.first)

    lead = SalesLead.find_or_initialize_by(
      facility_name: facility_name,
      phone: phone,
      region: @region
    )

    assign_attributes(lead, row)

    if lead.valid?
      lead.new_record? ? result.created += 1 : result.updated += 1
      lead.save!
    else
      result.errors << "Row #{row_number}: #{lead.errors.full_messages.join(', ')}"
    end
  rescue => e
    result.errors << "Row #{row_number}: #{e.message}"
  end

  def assign_attributes(lead, row)
    lead.assign_attributes(
      segment: extract_segment(row),
      area: extract_area(row),
      source: extract_value(row, source_keys),
      source_url: extract_value(row, source_url_keys),
      duplicate_flag: extract_duplicate_flag(row)
    )

    assign_sales_fields(lead, row) if @region_key == "chubu"
  end

  def assign_sales_fields(lead, row)
    lead.priority = extract_value(row, %w[優先度]) if extract_value(row, %w[優先度]).present?
    lead.it_literacy = extract_value(row, %w[IT化度 IT化度推定]) if extract_value(row, %w[IT化度 IT化度推定]).present?
    lead.sales_status = extract_sales_status(row) || lead.sales_status
    lead.person_in_charge = extract_value(row, %w[担当者 担当]) if extract_value(row, %w[担当者 担当]).present?
    lead.contacted_at = parse_date(extract_value(row, %w[初回接触日 接触日])) if extract_value(row, %w[初回接触日 接触日]).present?
    lead.appointment_date = parse_date(extract_value(row, %w[アポ日])) if extract_value(row, %w[アポ日]).present?
    lead.visited_at = parse_date(extract_value(row, %w[訪問日])) if extract_value(row, %w[訪問日]).present?
    lead.proposal_amount = parse_amount(extract_value(row, %w[提案金額 提案額])) if extract_value(row, %w[提案金額 提案額]).present?
    lead.subsidy_status = extract_value(row, %w[補助金申請状況 補助金 補助金申請]) if extract_value(row, %w[補助金申請状況 補助金 補助金申請]).present?
    lead.closed_at = parse_date(extract_value(row, %w[成約日])) if extract_value(row, %w[成約日]).present?
    lead.monthly_start_date = parse_date(extract_value(row, %w[月額開始日 月額開始])) if extract_value(row, %w[月額開始日 月額開始]).present?
    lead.memo = extract_value(row, %w[メモ 備考]) if extract_value(row, %w[メモ 備考]).present?
  end

  def facility_name_keys
    %w[施設名 宿泊施設名 ホテル名 名称]
  end

  def phone_keys
    %w[電話番号 TEL tel Phone phone]
  end

  def source_keys
    %w[ソース ソース分類 Source source]
  end

  def source_url_keys
    %w[URL ソースURL url]
  end

  def extract_segment(row)
    extract_value(row, %w[セグメント セグメント名 グループ])
  end

  def extract_area(row)
    extract_value(row, %w[市町村 エリア 地域])
  end

  def extract_value(row, keys)
    keys.each do |key|
      val = row[key]
      return val.to_s.strip if val.present?
    end
    nil
  end

  def extract_duplicate_flag(row)
    val = extract_value(row, %w[重複候補 重複])
    val.present?
  end

  def extract_sales_status(row)
    val = extract_value(row, %w[営業ステータス ステータス])
    return nil if val.blank?
    SalesLead::SALES_STATUSES.include?(val) ? val : nil
  end

  def normalize_phone(value)
    return nil if value.blank?
    value.to_s.strip.gsub(/[^0-9\-]/, "")
  end

  def parse_date(value)
    return nil if value.blank?
    return value if value.is_a?(Date)
    Date.parse(value.to_s)
  rescue Date::Error
    nil
  end

  def parse_amount(value)
    return nil if value.blank?
    return value.to_i if value.is_a?(Numeric)
    cleaned = value.to_s.gsub(/[^\d.]/, "")
    if value.to_s.include?("万")
      (cleaned.to_f * 10_000).to_i
    else
      cleaned.to_i
    end
  end
end
