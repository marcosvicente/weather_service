class Forecast < ApplicationRecord
  MAX_ARCHIVE_SIZE = 10.megabytes
  PROCESSING_STATUSES = %w[pending processing processed failed].freeze

  has_one_attached :weather_archive

  validates :processing_status, inclusion: { in: PROCESSING_STATUSES }
  validates :weather_archive, presence: true, on: :create
  validate :weather_archive_must_be_a_zip
  validates :zip_code, :address, presence: true, if: :processed?
  validates :current_temp, :high_temp, :low_temp, presence: true, numericality: true, if: :processed?
  validates :cached, inclusion: { in: [ true, false ] }, if: :processed?

  private

  def processed?
    processing_status == "processed"
  end

  def weather_archive_must_be_a_zip
    return unless weather_archive.attached?

    unless weather_archive.filename.to_s.downcase.end_with?(".zip")
      errors.add(:weather_archive, "must be a .zip file")
    end

    if weather_archive.blob.byte_size > MAX_ARCHIVE_SIZE
      errors.add(:weather_archive, "must be 10 MB or smaller")
    end
  end
end
