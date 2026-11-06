class AddArchiveProcessingToForecasts < ActiveRecord::Migration[8.1]
  def change
    add_column :forecasts, :weather_data, :jsonb, default: {}
    add_column :forecasts, :processing_status, :string, default: "pending", null: false
    add_column :forecasts, :processing_error, :text
  end
end
