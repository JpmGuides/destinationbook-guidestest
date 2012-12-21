class StatusController < ApplicationController

  def show
    render file: "#{Rails.root}/public/status.json", :formats => [:json]

    expires_now
  end

end
