class StatusController < ApplicationController

  def show
    json_path = "#{Rails.root}/public/status/status.json"
    html_path = "#{Rails.root}/public/status/status.html"

    respond_to do |format|
      format.json do
        if stale?(last_modified: File.mtime(json_path))
          send_file json_path, type: 'application/json', disposition: 'inline'
        end
      end
      format.html do
        if stale?(last_modified: File.mtime(html_path))
          send_file html_path, type: 'text/html', disposition: 'inline'
        end
      end
    end

  rescue
    # render nothing: true, status: 404
  end
end
