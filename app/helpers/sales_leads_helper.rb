module SalesLeadsHelper
  def priority_badge_class(priority)
    base = "inline-block px-2 py-0.5 rounded text-xs font-medium"
    case priority
    when "最高" then "#{base} bg-red-100 text-red-800"
    when "高"   then "#{base} bg-orange-100 text-orange-800"
    when "中"   then "#{base} bg-yellow-100 text-yellow-800"
    when "低"   then "#{base} bg-gray-100 text-gray-800"
    else base
    end
  end

  def sales_status_badge_class(status)
    base = "inline-block px-2 py-0.5 rounded text-xs font-medium"
    case status
    when "未着手"     then "#{base} bg-gray-100 text-gray-800"
    when "初回接触済" then "#{base} bg-blue-100 text-blue-800"
    when "アポ取得"   then "#{base} bg-indigo-100 text-indigo-800"
    when "訪問済"     then "#{base} bg-purple-100 text-purple-800"
    when "提案済"     then "#{base} bg-yellow-100 text-yellow-800"
    when "成約"       then "#{base} bg-green-100 text-green-800"
    when "失注"       then "#{base} bg-red-100 text-red-800"
    else base
    end
  end
end
