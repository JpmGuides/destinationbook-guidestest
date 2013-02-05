class StatusController < ApplicationController

  def show
    json_path =  "#{Rails.root}/public/status.json"

    if File.exists?(json_path)
      if stale?(last_modified: File.mtime(json_path))
        send_file json_path, type: 'application/json', disposition: 'inline'
      end
    else
      render nothing: true, status: 404
    end
  end

end
