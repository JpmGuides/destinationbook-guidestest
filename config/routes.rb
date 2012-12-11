Localguide::Application.routes.draw do

  match '/export', :controller => 'export', :action => 'show', :via => :get
  
end
