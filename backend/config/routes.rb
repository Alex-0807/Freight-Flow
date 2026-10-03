Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Run `bin/rails routes -g api` to list every endpoint below.
  namespace :api do
    namespace :v1 do
      resource :session, only: %i[create destroy]          # POST / DELETE /api/v1/session
      resource :me, only: :show, controller: "me"          # GET /api/v1/me
      resources :customers, only: :index                   # GET /api/v1/customers
      resources :drivers, only: :index                     # GET /api/v1/drivers
      resources :quotes, only: :create                     # POST /api/v1/quotes
      resources :consignments, only: %i[index show create] # GET, GET /:id, POST /api/v1/consignments
    end
  end
end
