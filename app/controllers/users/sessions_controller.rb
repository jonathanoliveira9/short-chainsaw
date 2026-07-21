class Users::SessionsController < Devise::SessionsController
  # JWT revocation happens in Warden::JWTAuth::Middleware::RevocationManager
  # based on the token payload, regardless of whether Warden considers the
  # request "signed in" — this check is only meaningful for session auth.
  skip_before_action :verify_signed_out_user, raise: false

  respond_to :json

  private

  def respond_with(resource, _opts = {})
    render json: { user: { id: resource.id, email: resource.email } }, status: :ok
  end

  # Devise's default implementation calls `respond_to`, which isn't
  # available on ActionController::API.
  def respond_to_on_destroy(non_navigational_status: :no_content)
    head non_navigational_status
  end
end
