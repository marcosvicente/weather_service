require "rails_helper"

RSpec.describe Forecast, type: :model do
  it { is_expected.to have_one_attached(:weather_archive) }

  it "accepts an attached ZIP before it has been processed" do
    forecast = described_class.new
    forecast.weather_archive.attach(
      io: StringIO.new("zip data"),
      filename: "weather.zip",
      content_type: "application/zip"
    )

    expect(forecast).to be_valid
  end

  it "requires a ZIP file" do
    forecast = described_class.new
    forecast.weather_archive.attach(
      io: StringIO.new("not a zip"),
      filename: "weather.txt",
      content_type: "text/plain"
    )

    expect(forecast).not_to be_valid
    expect(forecast.errors[:weather_archive]).to include("must be a .zip file")
  end
end
