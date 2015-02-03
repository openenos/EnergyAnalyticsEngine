=begin 
require 'cassandra'

s = Rufus::Scheduler.singleton

cluster = Cassandra.cluster
session  = cluster.connect()
time=(Time.now.utc).yesterday.beginning_of_hour.to_i
totalPowerValue = 0

s.cron '0 1 * * *' do  # for every hour
  
  session.execute("USE enos_sample")   
  Circuit.where(:active => true).each do |circuit|
    sum = 0
    results = session.execute("select * from emon_hourly_data where panel='#{circuit.panel.equip_ref}' and channel='#{circuit.channel_no}' and asof_hr>=#{time} and asof_hr<#{time.end_of_day.to_i}")
    
    results.each do |row|
      sum = row['value'].to_f + sum
    end 

    sum = sum / 1000;

    totalPowerValue +=sum if circuit.input

    EmonDailyData.create(:circuit_id => circuit.id, :value => totalPowerValue, :as_of_day => time.end_of_day.to_i, :year => Time.now.year)
  end

end

=end