require 'rails_helper'

RSpec.describe Forecast, type: :model do
  it { is_expected.to validate_presence_of(:zip_code) }
  it { is_expected.to validate_presence_of(:address) }
  it { is_expected.to validate_presence_of(:current_temp) }
  it { is_expected.to validate_presence_of(:high_temp) }
  it { is_expected.to validate_presence_of(:low_temp) }

  it { is_expected.to validate_numericality_of(:current_temp) }
  it { is_expected.to validate_numericality_of(:high_temp) }
  it { is_expected.to validate_numericality_of(:low_temp) }

  it 'allows cached to be false' do
    forecast = Forecast.new(
      zip_code: '10001',
      address: 'New York, NY',
      current_temp: 20,
      high_temp: 25,
      low_temp: 15,
      cached: false
    )

    expect(forecast).to be_valid
  end

  it 'requires cached to be set' do
    forecast = Forecast.new(
      zip_code: '10001',
      address: 'New York, NY',
      current_temp: 20,
      high_temp: 25,
      low_temp: 15
    )

    expect(forecast).not_to be_valid
    expect(forecast.errors[:cached]).to be_present
  end
end
