# frozen_string_literal: true

namespace :thumbnail do
  desc "Test thumbnail generation with Hugging Face API"
  task :test, [:action_plan] => :environment do |_t, args|
    action_plan = args[:action_plan] || "【やってみた】朝5時起きを1週間続けた結果"

    puts "=" * 50
    puts "Thumbnail Generation Test (Hugging Face)"
    puts "=" * 50
    puts "Action Plan: #{action_plan}"
    puts "API Key: #{ENV['HUGGINGFACE_API_KEY'].present? ? 'Set' : 'NOT SET'}"
    puts "Generating... (may take 30-60 seconds)"
    puts

    result = HuggingfaceService.generate_thumbnail(action_plan)

    if result[:success]
      puts "Success!"
      puts "MIME Type: #{result[:mime_type]}"
      puts "Image Data Size: #{result[:image_data].length} bytes (base64)"

      # 画像をファイルに保存
      output_path = Rails.root.join("tmp", "test_thumbnail_#{Time.now.to_i}.png")
      File.open(output_path, "wb") do |f|
        f.write(Base64.decode64(result[:image_data]))
      end
      puts "Saved to: #{output_path}"
      puts
      puts "Open the file to check the quality!"
    else
      puts "Failed!"
      puts "Error: #{result[:error]}"
      if result[:retry_after]
        puts "Retry after: #{result[:retry_after]} seconds"
      end
    end
  end
end
