require "rails_helper"
require "zip"

RSpec.describe ForecastArchiveProcessor do
  let(:forecast) { Forecast.new }
  let(:weather_data) { JSON.parse(Rails.root.join("spec/fixtures/weather_forecast.json").read) }

  def attach_archive(forecast, files)
    buffer = Zip::OutputStream.write_buffer do |zip|
      files.each do |filename, data|
        zip.put_next_entry(filename)
        zip.write(data)
      end
    end
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(buffer.string),
      filename: "weather.zip",
      content_type: "application/zip"
    )
    forecast.weather_archive.attach(blob)
  end

  it "imports forecast values and stores every JSON file from the archive" do
    attach_archive(forecast, [
      [ "forecasts/weather.json", JSON.generate(weather_data) ],
      [ "metadata.json", JSON.generate("source" => "fixture") ]
    ])
    forecast.save!

    described_class.call(forecast.id)
    forecast.reload

    expect(forecast).to have_attributes(
      zip_code: "20500",
      address: "White House, Washington, DC",
      current_temp: 18.5,
      high_temp: 22.0,
      low_temp: 12.0,
      cached: false,
      processing_status: "processed"
    )
    expect(forecast.weather_data.fetch("files").size).to eq(2)
    expect(forecast.weather_data.fetch("files").first.fetch("data")).to include(
      "current" => include("temperature_2m" => 18.5)
    )
  end

  it "marks an archive without JSON files as failed" do
    attach_archive(forecast, [ [ "readme.txt", "no forecast" ] ])
    forecast.save!

    described_class.call(forecast.id)

    expect(forecast.reload).to have_attributes(
      processing_status: "failed",
      processing_error: "The ZIP archive does not contain any JSON files."
    )
  end

  it "marks malformed JSON as failed" do
    attach_archive(forecast, [ [ "weather.json", "{invalid json" ] ])
    forecast.save!

    described_class.call(forecast.id)

    expect(forecast.reload).to have_attributes(processing_status: "failed")
    expect(forecast.processing_error).to match(/Unable to read the ZIP archive/)
  end
end
