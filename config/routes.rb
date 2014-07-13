Rails.application.routes.draw do
  resources :heatmaps do
    collection do
      get 'filters'
      get 'points'
    end
  end
  root 'heatmaps#index'
end
