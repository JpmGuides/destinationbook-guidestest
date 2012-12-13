class ExportController < ApplicationController

  def show

    json_path = "#{Settings.path.guides_generated}/#{params[:guide_id]}/guide.json"

    json_path = File.exists?(json_path) ? json_path : nil

    if json_path.nil?
      render nothing: true, status: 404
    else
      render file: json_path, content_type: 'application/json'
    end

    expires_now
  end

end
