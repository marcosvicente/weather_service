class ForecastsController < ApplicationController
  def index
    @forecast = Forecast.new
  end

  def show
    @forecast = Forecast.find(params[:id])
  end

  def create
    @forecast = Forecast.new
    @forecast.weather_archive = forecast_params[:weather_archive]

    if @forecast.save
      ProcessForecastArchiveJob.perform_later(@forecast.id)
      redirect_to @forecast, notice: "The archive was uploaded and processing has started."
    else
      render :index, status: :unprocessable_entity
    end
  end

  private

  def forecast_params
    params.require(:forecast).permit(:weather_archive)
  end
end
