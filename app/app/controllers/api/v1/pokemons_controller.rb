module Api
  module V1
    class PokemonsController < ApplicationController
      # GET /api/v1/pokemons?q=ピカ&limit=20
      def index
        @pokemons = Pokemon.search(params[:q]).dex_order.limit(limit_param)
      end

      # GET /api/v1/pokemons/10100 or /api/v1/pokemons/raichu-alola
      def show
        @pokemon = Pokemon.find_by_key!(params[:id])
      end
    end
  end
end
