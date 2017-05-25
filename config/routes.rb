Rails.application.routes.draw do
  mount JasmineRails::Engine => '/specs' if defined?(JasmineRails)
  match '/' => redirect('graph'), via: :get
  resources :elos, :only => [:index]
  resources :games, :except => [:destroy, :show]
  resources :teams, :except => [:destroy, :show]
  resources :seasons, :except => [:destroy, :show]
  match 'seasons/refresh', :to => 'seasons#refresh', :via => [:get]
  match 'graph', :to => 'elos#graph',   :via => [:get]
  match 'lines', :to => 'elos#money_lines',   :via => [:get]
  match 'users', :to => 'users#create', :via => [:post]
  match 'login', :to => 'users#index',  :via => [:get]
  match 'logout',:to => 'users#logout', :via => [:get]
end
