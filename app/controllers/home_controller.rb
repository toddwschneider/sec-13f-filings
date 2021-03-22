class HomeController < ApplicationController
  layout "home"

  def index
    expires_in 15.minutes, public: true
  end
end
