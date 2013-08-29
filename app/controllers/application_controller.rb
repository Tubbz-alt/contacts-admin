class ApplicationController < ActionController::Base
  include Slimmer::Headers
  include Slimmer::Template

  protect_from_forgery with: :exception

  after_filter :skip_slimmer
  before_filter :set_ariane

  decent_configuration do
    strategy DecentExposure::StrongParametersStrategy
  end

  def skip_slimmer
    response.headers[Slimmer::Headers::SKIP_HEADER] = "true" if params[:skip_slimmer]
  end

  def set_ariane
    ariane.add ''
  end
end
