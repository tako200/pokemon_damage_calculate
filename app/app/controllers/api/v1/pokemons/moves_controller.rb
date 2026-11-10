module Api
  module V1
    module Pokemons
      # 選んだポケモンがチャンピオンズで覚えられる技の検索
      class MovesController < ApplicationController
        # GET /api/v1/pokemons/445/moves?q=じし&damage_class=physical&type=ground
        # 1 匹が覚える技は多くても 150 程度なので、limit を指定しなければ全件返す
        def index
          pokemon = Pokemon.find_by_key!(params[:pokemon_id])
          @moves = pokemon.learnable_moves
                          .search(params[:q])
                          .with_damage_class(params[:damage_class])
                          .with_type(params[:type])
                          .power_order
          @moves = @moves.limit(limit_param) if params[:limit].present?

          render "api/v1/moves/index"
        end
      end
    end
  end
end
