class StatusController < ApplicationController

  def show
    render file: "#{Rails.root}/public/status.json", content_type: 'application/json'

    expires_now
  end

end
