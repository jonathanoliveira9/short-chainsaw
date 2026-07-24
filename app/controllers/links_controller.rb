# frozen_string_literal: true

class LinksController < ApplicationController
  before_action :authenticate_user!, except: [ :show ]
  before_action :set_link, only: [ :update, :destroy ]

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_invalid

  def generate
    link = Link.generate_for(user: current_user, long_link: link_param)

    render json: { short_link: link.short_link, expires_at: link.expires_at }, status: :created
  end

  def show
    link = Link.available.find_by!(short_link: params[:short_link])

    response.set_header("Location", link.long_link)
    head :found
  end

  def update
    @link.update!(long_link: link_param)
    head :ok
  end

  def destroy
    @link.destroy!
    head :no_content
  end

  private

  def set_link
    @link = current_user.links.find_by!(short_link: params[:short_link])
  end

  def link_param
    params.expect(:link)
  end

  def render_not_found
    head :not_found
  end

  def render_invalid(exception)
    render json: { errors: exception.record.errors }, status: :unprocessable_entity
  end
end
