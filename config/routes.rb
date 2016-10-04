Rails.application.routes.draw do
  resources :elos
  resources :games
  resources :teams
  mount JasmineRails::Engine => '/specs' if defined?(JasmineRails)
  resources :seasons
end
