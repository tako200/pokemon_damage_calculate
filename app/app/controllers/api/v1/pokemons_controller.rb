module Api
  module V1
    class PokemonsController < ApplicationController
      DEFAULT_LIMIT = 20
      MAX_LIMIT = 100

      # GET /api/v1/pokemons?q=ピカ&limit=20
      def index
        limit = params.fetch(:limit, DEFAULT_LIMIT).to_i.clamp(1, MAX_LIMIT)
        @pokemons = Pokemon.search(params[:q]).dex_order.limit(limit)
      end

      # GET /api/v1/pokemons/10100 or /api/v1/pokemons/raichu-alola
      def show
        key = params[:id]
        @pokemon = key.match?(/\A\d+\z/) ? Pokemon.find_by!(pokeapi_id: key) : Pokemon.find_by!(name: key)
      end
    end
  end
end
