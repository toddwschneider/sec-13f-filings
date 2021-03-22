class ApplicationController < ActionController::Base

  private

  def parsed_cusip
    params[:cusip].upcase
  end
end
