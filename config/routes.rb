Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'application#index'
  get '/info' => 'application#info'
  get '/heatmap' => 'application#heatmap'
  get '/submitted' => 'application#submitted'
  match '/auth/:provider/callback', to: 'application#oauth', via: [:get, :post]
end
