namespace :document do

  desc 'Update all guides if necessary'
  task :generate_all => :environment do
    puts 'updating document pages'
    Document.all.each do |document|
      begin 
        puts "generate page for document : #{document.id}/#{document.title}"
        document.file.cache_stored_file!
        document.file.generate_pages_for_export(document.file)
      rescue
        puts "document : #{document.id}/#{document.title}, does not exist"
      end
    end
    puts 'update terminated'
  end

end