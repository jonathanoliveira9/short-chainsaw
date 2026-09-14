# frozen_string_literal: true

class LinksController < ApplicationController
  before_action :authenticate_user!, except: [ :show ]

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_invalid
  rescue_from ShortCodeGenerator::UnavailableError, with: :render_service_unavailable

  def generate
    link = Link.generate_for(user: current_user, long_link: link_param)

    render json: { short_link: link.short_link, expires_at: link.expires_at }, status: :created
  end

  def show
    link = Link.on_shard_for(params[:short_link]) { Link.available.find_by!(short_link: params[:short_link]) }

    response.set_header("Location", link.long_link)
    head :found
  end

  def update
    Link.on_shard_for(params[:short_link]) { find_owned_link!.update!(long_link: link_param) }
    head :ok
  end

  def destroy
    Link.on_shard_for(params[:short_link]) { find_owned_link!.destroy! }
    head :no_content
  end

  private

  # Must run inside the same `on_shard_for` block as the find (and any
  # mutation), since the shard context is only active for that block's
  # duration.
  def find_owned_link!
    current_user.links.find_by!(short_link: params[:short_link])
  end

  def link_param
    params.expect(:link)
  end

  def render_not_found
    head :not_found
  end

  def render_service_unavailable
    head :service_unavailable
  end

  def render_invalid(exception)
    render json: { errors: exception.record.errors }, status: :unprocessable_entity
  end
end
