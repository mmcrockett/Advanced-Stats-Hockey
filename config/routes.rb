Rails.application.routes.draw do
  mount JasmineRails::Engine => '/specs' if defined?(JasmineRails)
  match '/' => redirect('graph'), via: :get
  resources :elos, :except  => [:destroy, :show]
  resources :games, :except => [:destroy, :show]
  resources :teams, :except => [:destroy, :show]
  resources :seasons, :except => [:destroy, :show]
  match 'graph', :to => 'elos#graph',   :via => [:get]
  match 'users', :to => 'users#create', :via => [:post]
  match 'login', :to => 'users#index',  :via => [:get]
  match 'logout',:to => 'users#logout', :via => [:get]
end
