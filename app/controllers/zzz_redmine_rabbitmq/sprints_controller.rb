class ZzzRedmineRabbitmq::SprintsController < ApplicationController
  unloadable

  before_action :check_api_key

  DEFAULT_LIMIT = 100

  def index
    offset = params[:offset].to_i
    limit = (params[:limit] || DEFAULT_LIMIT).to_i

    @sprints = Sprint.limit(limit).offset(offset)
    render json: { sprints: @sprints }
  end

  private

  def check_api_key
    api_key = params[:key]
    user = User.find_by_api_key(api_key)

    unless user
      render json: { error: 'Invalid API key' }, status: :unauthorized
      return
    end
  end
end
