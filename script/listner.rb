APP_PATH = File.expand_path('../../config/application',  __FILE__)
require File.expand_path('../../config/boot',  __FILE__)
require File.expand_path('../../config/environment',  __FILE__)

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
  ROOT = Rails.root

  begin

    write_status_message = Proc.new do |guide_id, status_name, status_message|
      File.open("#{ROOT}/public/status.json", 'rb+') do |file|
        status = JSON.parse(file.read).shift(49) rescue []

        status.unshift(
          time: Time.now.to_i,
          guide_id: guide_id,
          status: status_name,
          message: status_message
        )

        file.truncate(0)
        file.write(status.to_json)
      end
    end

    orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily
    local_ip = UDPSocket.open do |s|
      s.connect '64.233.187.99', 1
      s.addr.last
    end

    puts "---------------------------------------------------"
    puts "Server is accessible by it's hostname : #{`hostname`}"
    puts "or by it's ip: #{local_ip}"
    puts "Waiting for guide zip in:"
    puts "#{ROOT}/public/zip"
    puts "---------------------------------------------------"

    Listen.to("#{ROOT}/public/zip", latency: 1, filter: /\.zip$/) do |modified, added|
      (modified + added).each do |change|
        guide_id = File.basename(change, '.*')

        waiting = 0
        begin
          guide_zip = Zip::File.open(change)
        rescue
          if waiting > 0
            print '.'
          else
            print "#{guide_id}: waiting on zip file."
          end

          if waiting <= 10.minutes
            waiting += 1
            sleep 1
            retry
          else
            raise
          end
        end
        print "\n" if waiting > 0

        begin
          # display starting process in console
          puts "#{guide_id}: generation started"

          # cleanup old generated guide
          FileUtils.rm_rf("#{Rails.root}/public/guides/#{guide_id}")

          # generate guide
          ExportWallet::Guide.new(guide_id, change, guide_zip).generate

          # display success message
          puts "#{guide_id}: generated successfully"
          write_status_message.call(guide_id, 'successfull')

        rescue => e
          # display error in guide generation
          puts "#{guide_id}: generation failed\n#{e.message}"
          write_status_message.call(guide_id, 'error', e.message)

        ensure
          # remove guide zip
          FileUtils.rm("#{Rails.root}/public/zip/#{guide_id}.zip")
        end
      end
    end

  end
end

