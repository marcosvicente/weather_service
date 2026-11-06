class ProcessForecastArchiveJob < ApplicationJob
  def perform(forecast_id)
    ForecastArchiveProcessor.call(forecast_id)
  end
end
