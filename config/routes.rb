Localguide::Application.routes.draw do

  match '/export', :controller => 'export', :action => 'show', :via => :get

  match '/status.json', :controller => 'export', :action => 'show', :via => :get

  match '/stats', :controller => 'status', :action => 'show', :via => :get

  root to: 'status#show'
end
