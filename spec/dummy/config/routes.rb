Rails.application.routes.draw do
  devise_for :users
  get 'secret', to: 'home#secret'
  post 'quick_sign_in', to: 'home#quick_sign_in'
  root to: 'home#index'
end
