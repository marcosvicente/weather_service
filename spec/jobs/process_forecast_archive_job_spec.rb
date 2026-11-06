require "rails_helper"
require "zip"

RSpec.describe ProcessForecastArchiveJob, type: :job do
  it "processes a saved forecast archive" do
    weather_data = JSON.parse(Rails.root.join("spec/fixtures/weather_forecast.json").read)
    buffer = Zip::OutputStream.write_buffer do |zip|
      zip.put_next_entry("weather_forecast.json")
      zip.write(JSON.generate(weather_data))
    end
    forecast = Forecast.new
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(buffer.string),
      filename: "weather.zip",
      content_type: "application/zip"
    )
    forecast.weather_archive.attach(blob)
    forecast.save!

    described_class.perform_now(forecast.id)

    expect(forecast.reload.processing_status).to eq("processed")
  end

  it "marks an invalid archive as failed with an error message" do
    forecast = Forecast.new
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("not a zip"),
      filename: "weather.zip",
      content_type: "application/zip"
    )
    forecast.weather_archive.attach(blob)
    forecast.save!

    described_class.perform_now(forecast.id)

    expect(forecast.reload.processing_status).to eq("failed")
    expect(forecast.processing_error).to be_present
  end
end
