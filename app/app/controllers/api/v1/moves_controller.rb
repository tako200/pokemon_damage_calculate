module Api
  module V1
    # 全技からの検索（覚える技のデータに漏れがあったときの予備）
    class MovesController < ApplicationController
      # GET /api/v1/moves?q=じしん&damage_class=physical&type=ground&limit=20
      def index
        @moves = Move.search(params[:q])
                     .with_damage_class(params[:damage_class])
                     .with_type(params[:type])
                     .power_order
                     .limit(limit_param)
      end

      # GET /api/v1/moves/89 or /api/v1/moves/earthquake
      def show
        @move = Move.find_by_key!(params[:id])
      end
    end
  end
end
