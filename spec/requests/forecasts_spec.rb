require "rails_helper"
require "zip"

RSpec.describe "Forecasts", type: :request do
  let(:archive_file) do
    json = JSON.parse(Rails.root.join("spec/fixtures/weather_forecast.json").read)
    buffer = Zip::OutputStream.write_buffer do |zip|
      zip.put_next_entry("weather_forecast.json")
      zip.write(JSON.generate(json))
    end
    file = Tempfile.new([ "weather_forecast", ".zip" ])
    file.binmode
    file.write(buffer.string)
    file.rewind
    file
  end
  let(:archive_upload) do
    Rack::Test::UploadedFile.new(
      archive_file.path,
      "application/zip",
      original_filename: "weather_forecast.zip"
    )
  end

  after do
    archive_file.close!
  end

  it "shows a ZIP upload form on the home page" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("ZIP archive")
    expect(response.body).to include("Upload archive")
  end

  it "saves the uploaded archive and enqueues its processing" do
    expect {
      post forecasts_path, params: { forecast: { weather_archive: archive_upload } }
    }.to have_enqueued_job(ProcessForecastArchiveJob)

    forecast = Forecast.last
    expect(response).to redirect_to(forecast_path(forecast))
    expect(forecast.weather_archive).to be_attached
    expect(forecast.processing_status).to eq("pending")

    get forecast_path(forecast)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Archive status")
    expect(response.body).to include("The archive is being processed")
  end

  it "rejects a request without a ZIP upload" do
    post forecasts_path, params: { forecast: { weather_archive: nil } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Weather archive")
    expect(Forecast.count).to eq(0)
  end
end
