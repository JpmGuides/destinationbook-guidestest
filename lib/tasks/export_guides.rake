namespace :update_guides do

  desc 'Update all guides if necessary'
  task :all => :environment do
    puts 'updating guides'
    ExportGuides.new.update_guides
    puts 'update terminated'
  end
  
  desc 'Force update all guides'
  task :force => :environment do
    puts 'updating guides'
    ExportGuides.new.update_guides(true)
    puts 'update terminated'
  end

end