namespace :listner do

  desc 'start a listner to update guides'
  task :start => :environment do
    
    Listen.to("#{Rails.root}/public/zip", latency: 10, filter: /\.zip/) do |modified, added|
  
      changes = modified + added
      tries = 0

      changes.each do |change|
        begin
          guide_id = File.basename(change, '.*')
          guide = ExportGuides::Guide.new(guide_id, change, Zip::ZipFile.open(change)) 
          guide.generate
          puts "guide #{guide_id} was generated successfully"
        rescue => e
          if e.message != 'Zip end of central directory signature not found'
            puts "error on guide #{guide_id} : #{e.message}"
            puts "generation of #{guide_id} failed"
          else
            changes.push(change)
            sleep 1
          end
	end
      end
    end
  end

end
