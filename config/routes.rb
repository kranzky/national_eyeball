Rails.application.routes.draw do
  resources :heatmaps do
    collection do
      get 'filters'
      get 'points'
      get 'comments'
    end
  end
  root 'heatmaps#index'
end
