class ApplicationController < ActionController::API
  DEFAULT_LIMIT = 20
  MAX_LIMIT = 100

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "not_found" }, status: :not_found
  end

  private

  # ?limit= を 1〜MAX_LIMIT に丸める
  def limit_param
    params.fetch(:limit, DEFAULT_LIMIT).to_i.clamp(1, MAX_LIMIT)
  end
end
