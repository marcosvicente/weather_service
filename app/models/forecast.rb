class Forecast < ApplicationRecord
  validates :zip_code, :address, presence: true
  validates :current_temp, :high_temp, :low_temp, presence: true, numericality: true
  validates :cached, inclusion: { in: [true, false] }
end
