Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  root "pages#index"
  get "/docs", to: "pages#docs"
  get "/login_test", to: "pages#index"
  get "/example.txt", to: "pages#test_password"
  post "/register", to: "registrations#create"
  post "/login", to: "sessions#create"
end
