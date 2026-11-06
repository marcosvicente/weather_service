require "json"
require "zip"

class ForecastArchiveProcessor
  MAX_JSON_FILES = 20
  MAX_JSON_FILE_SIZE = 5.megabytes
  MAX_TOTAL_JSON_SIZE = 10.megabytes

  class Error < StandardError
  end

  def self.call(forecast_id)
    new(Forecast.find(forecast_id)).call
  end

  def initialize(forecast)
    @forecast = forecast
  end

  def call
    @forecast.update!(processing_status: "processing")
    process_archive
  rescue Error => error
    @forecast.update!(processing_status: "failed", processing_error: error.message)
    @forecast
  end

  private

  def process_archive
    files = read_json_files
    weather_file = files.find { |file| weather_values(file.fetch("data")) }
    raise Error, "The ZIP archive does not contain a valid weather forecast JSON file." unless weather_file

    data = weather_file.fetch("data")
    current_temp, high_temp, low_temp = weather_values(data)
    zip_code = data["zip_code"] || data["postal_code"]
    raise Error, "The weather JSON must include a ZIP code." if zip_code.blank?

    @forecast.update!(
      zip_code: zip_code.to_s,
      address: data["address"].presence || "ZIP #{zip_code}",
      current_temp: current_temp,
      high_temp: high_temp,
      low_temp: low_temp,
      cached: false,
      weather_data: { "files" => files },
      processing_status: "processed",
      processing_error: nil
    )
  rescue Zip::Error, JSON::ParserError, EOFError => error
    raise Error, "Unable to read the ZIP archive: #{error.message}"
  end

  def read_json_files
    archive = @forecast.weather_archive
    raise Error, "No ZIP archive is attached to this forecast." unless archive.attached?
    if archive.blob.byte_size > Forecast::MAX_ARCHIVE_SIZE
      raise Error, "The ZIP archive exceeds the 10 MB size limit."
    end

    total_size = 0
    files = []
    Zip::File.open_buffer(archive.download) do |zip_file|
      entries = zip_file.entries.select do |entry|
        !entry.directory? && File.extname(entry.name).casecmp(".json").zero?
      end

      raise Error, "The ZIP archive does not contain any JSON files." if entries.empty?
      if entries.size > MAX_JSON_FILES
        raise Error, "The ZIP archive contains more than #{MAX_JSON_FILES} JSON files."
      end

      files = entries.map do |entry|
        if entry.size > MAX_JSON_FILE_SIZE
          raise Error, "#{entry.name} exceeds the 5 MB size limit."
        end

        total_size += entry.size
        if total_size > MAX_TOTAL_JSON_SIZE
          raise Error, "The JSON files exceed the 10 MB total size limit."
        end

        content = entry.get_input_stream.read(MAX_JSON_FILE_SIZE + 1)
        if content.bytesize > MAX_JSON_FILE_SIZE
          raise Error, "#{entry.name} exceeds the 5 MB size limit."
        end

        data = JSON.parse(content)
        raise Error, "#{entry.name} must contain a JSON object." unless data.is_a?(Hash)

        { "filename" => entry.name, "data" => data }
      end
    end
    files
  end

  def weather_values(data)
    current_temp = data.dig("current", "temperature_2m")
    high_temp = data.dig("daily", "temperature_2m_max")&.first
    low_temp = data.dig("daily", "temperature_2m_min")&.first
    return if [ current_temp, high_temp, low_temp ].any? { |value| !value.is_a?(Numeric) }

    [ current_temp, high_temp, low_temp ]
  end
end
