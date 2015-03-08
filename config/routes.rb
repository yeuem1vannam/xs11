Rails.application.routes.draw do
  root to: "teams#index"
  resources :players

  resources :teams

end
