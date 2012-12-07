namespace :listner do

  desc 'start a listner to update guides'
  task :start => :environment do
    Listen.to("#{Rails.root}/public/zip") do |modified, added|
  
      changes = modified + added

      changes.each do |change|
        puts change
        guide_id = File.basename(change, '.*')
        guide = ExportGuides::Guide.new(guide_id, change, Zip::ZipFile.open(change)) 
        guide.generate
      end
    end
  end

end