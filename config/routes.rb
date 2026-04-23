Rails.application.routes.draw do
  devise_for :users

  namespace :api do
    resources :inquiries, only: %i[create]
  end

  resources :stays, only: %i[index new create edit update] do
    member do
      patch :cancel
    end
  end

  resources :inquiries, only: %i[index show]

  resources :users, only: %i[index new create edit update] do
    member do
      patch :toggle_active
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  root "stays#index"
end
