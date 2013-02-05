Localguide::Application.routes.draw do

  match '/export', :controller => 'export', :action => 'show', :via => :get

  match '/status', :controller => 'status', :action => 'show', :via => :get

  root to: 'status#show'
end
