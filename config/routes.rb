Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  root "pages#index"
  get "/login_test", to: "pages#index"
  post "/register", to: "registrations#create"
  post "/login", to: "sessions#create"
end
