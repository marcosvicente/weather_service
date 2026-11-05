class CreateForecasts < ActiveRecord::Migration[8.1]
  def change
    create_table :forecasts do |t|
      t.string :zip_code
      t.string :address
      t.decimal :current_temp
      t.decimal :high_temp
      t.decimal :low_temp
      t.boolean :cached

      t.timestamps
    end
  end
end
