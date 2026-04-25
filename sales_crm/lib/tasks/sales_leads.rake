namespace :sales_leads do
  desc "Excel ファイルから営業先リストをインポート（冪等）"
  task :import, [ :directory ] => :environment do |_t, args|
    directory = args[:directory] || "tmp/import"

    file_map = {
      "north" => Dir.glob(File.join(directory, "*north*")).first,
      "chubu" => Dir.glob(File.join(directory, "*chubu*")).first,
      "south" => Dir.glob(File.join(directory, "*south*")).first
    }

    file_map.each do |region_key, file_path|
      if file_path.nil?
        puts "[SKIP] #{region_key}: ファイルが見つかりません (#{directory})"
        next
      end

      puts "[START] #{region_key}: #{File.basename(file_path)}"
      result = SalesLeadImporter.new(file_path, region_key: region_key).import
      puts "  作成: #{result.created}, 更新: #{result.updated}, スキップ: #{result.skipped}"
      if result.errors.any?
        puts "  エラー (#{result.errors.size}件):"
        result.errors.each { |e| puts "    #{e}" }
      end
      puts "[DONE] #{region_key}"
      puts
    end
  end
end
