Rails.application.routes.draw do
  devise_for :users

  resources :sales_leads, only: %i[index show new create edit update]

  get "up" => "rails/health#show", as: :rails_health_check

  root "sales_leads#index"
end
