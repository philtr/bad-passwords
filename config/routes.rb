Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  root "pages#index"
  get "/docs", to: "pages#docs"
  get "/faq", to: "pages#faq"
  get "/login_test", to: "pages#index"
  get "/example.txt", to: "pages#test_password"
  get "/validate", to: "tokens#new"
  post "/register", to: "registrations#create"
  post "/login", to: "sessions#create"
  post "/validate", to: "tokens#validate"
  delete "/logout", to: "sessions#destroy"
end
