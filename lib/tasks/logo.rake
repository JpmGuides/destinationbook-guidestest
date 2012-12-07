namespace :logo do

  desc 'generate all logo for trip and client'
  task :generate_all => :environment do
    puts 'generate logos'
    Client.where('logo IS NOT NULL').each do |client|
      begin 
        puts "generate logo for client : #{client.id}"
        client.logo.cache_stored_file!
        client.logo.generate_logo_for_export(client.logo)
      rescue
        puts "logo for client : #{client.id}, does not exist"
      end
    end

    Trip.where('logo IS NOT NULL').each do |trip|
      begin 
        puts "generate logo for trip : #{trip.id}"
        trip.logo.cache_stored_file!
        trip.logo.generate_logo_for_export(trip.logo)
      rescue
        puts "logo for trip : #{trip.id}, does not exist"
      end
    end
    puts 'generation terminated'
  end

end