Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # SwiftUI クライアント向け API
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :pokemons, only: %i[index show] do
        # GET /api/v1/pokemons/:pokemon_id/moves（そのポケモンが覚えられる技）
        resources :moves, only: :index, module: :pokemons
      end
      resources :moves, only: %i[index show]
    end
  end
end
