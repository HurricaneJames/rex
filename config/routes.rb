Rails.application.routes.draw do
  get 'pages/index'
  root to: 'pages#index'
end
