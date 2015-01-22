class CreateEmonDailyData < ActiveRecord::Migration
  def change
    create_table :emon_daily_data do |t|
      t.integer :circuit_id
      t.integer :year
      t.integer :as_of_day
      t.float :value

      t.timestamps
    end
  end
end
