class ManagersController < ApplicationController
  def index
    expires_in 1.hour, public: true

    @filers = ThirteenFFiler.
      order("lower(name), cik").
      page(params[:page])
  end
end
