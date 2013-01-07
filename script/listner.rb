
APP_PATH = File.expand_path('../../config/application',  __FILE__)
require File.expand_path('../../config/boot',  __FILE__)

require 'lib/export_guides'
require 'socket'
require 'daemons'
require 'listen'
require 'json'

options = {
  :dir_mode   => :script,
  :log_output => true,
  :ontop      => true,
  :multiple   => false
}

Daemons.run_proc('listner.rb', options) do

  ROOT = '/var/www/local_guide'

  begin 
    json_status_file = "#{ROOT}/public/status.json"

    orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily
    local_ip = UDPSocket.open do |s|
      s.connect '64.233.187.99', 1
      s.addr.last
    end

    puts "---------------------------------------------------"
    puts "Server is accessible by it's hostname : #{`hostname`}"
    puts "or by it's ip : #{local_ip}"
    puts "---------------------------------------------------"

    Listen.to("#{ROOT}/public/zip", latency: 10, filter: /\.zip/) do |modified, added|

      changes = modified + added

      changes.each do |change|
        begin

          guide_id = File.basename(change, '.*')
          guide = ExportGuides::Guide.new(guide_id, change, Zip::ZipFile.open(change))
          FileUtils.rm_rf("#{ROOT}/public/guides/#{guide_id}")
          guide.generate

          puts "guide #{guide_id} was generated successfully"

          begin
            status = JSON.parse(File.read(json_status_file))
          rescue
            status = []
          end
          
          status.unshift({:time => Time.now.to_i, :guide_id => guide_id, :status => 'successfull'})
          status.pop if status.count >  50
          
          File.open(json_status_file, 'wb+') do |f|
            f.write(status.to_json)
          end

        rescue => e

          if e.message != 'Zip end of central directory signature not found'
            puts "error on guide #{guide_id} : #{e.message}"
            puts "generation of #{guide_id} failed"
            
            begin
              status = JSON.parse(File.read(json_status_file))
            rescue
              status = []
            end
            status.unshift({:time => Time.now.to_i, :guide_id => guide_id, :status => 'error', :message => e.message})
            status.pop if status.count >  50
            File.open(json_status_file, 'wb+') do |f|
              f.write(status.to_json)
            end

          else
            changes.push(change)
            sleep 1
          end

        end
      end

    end
  end

end