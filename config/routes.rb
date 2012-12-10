Localguide::Application.routes.draw do

  match '/export/:id', :controller => 'export', :action => 'show', :via => :get
  
end
