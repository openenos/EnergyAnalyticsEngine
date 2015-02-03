class Ws::SiteGroupsController < ApplicationController

  def get_all_groups
    siteGroups = SiteGroup.select("id, display")
    respond_to do |format|
      format.json { render :json => siteGroups unless siteGroups.nil? }
    end    
  end

  def current_demand_by_group
    site_data_json = {}
    params[:group_id] ||= SiteGroup.first.id
    site_data_json[:group_id] = params[:group_id]
    site_data_json[:demand_sum] = sum_of_demand_avg_values
    render :json =>  site_data_json
  end


  def solar_power_by_group
    site_data_json = {}
    params[:group_id] ||= SiteGroup.first.id
    site_data_json[:group_id] = params[:group_id]
    site_data_json[:solar_sum] = sum_of_solar_avg_values
    render :json =>  site_data_json
  end

  def utilityPower
    params[:group_id] ||= SiteGroup.first.id
    site_data_json = {}
    utility_power = ((sum_of_demand_avg_values) - (sum_of_solar_avg_values)) 
    if utility_power >=0
      site_data_json[:utility_flag] =  true
    else
      site_data_json[:utility_flag] =  false
    end

    site_data_json[:group_id] = params[:group_id]
    site_data_json[:utility_power] = utility_power.abs
    render :json =>  site_data_json
  end

  def usage_by_group  
    if params[:group_id].nil? || params[:from].nil? || params[:to].nil?
      json_data = {"Error" => "Required Parameters: #{'group_id' if params[:group_id].nil?} #{'date_from' if params[:from].nil?} #{'date_to' if params[:to].nil?}"}
    elsif params[:group_id].empty? || params[:from].empty? || params[:to].empty?
      json_data = {"Error" => "Required Parameters: #{'group_id' if params[:group_id].empty?} #{'date_from' if params[:from].empty?} #{'date_to' if params[:to].empty?}"}
    else

      begin
        group_id = params[:group_id]
        date_from =  params[:from] # format "02-06-2014"
        date_to =  params[:to] # format "03-06-2014"
        group_time_zone = SiteGroup.find(params[:group_id]).sites.first.location.postal_code.tz
        endingDay = (date_to.to_datetime.beginning_of_day.to_time).utc.to_i
        beginningDay = (date_from.to_datetime.end_of_day.to_time).utc.to_i

        json_data = []
        SiteGroupMapping.where(site_group_id: group_id).each do|siteGroupMapping|
          site_data_json = {}
          site_data_json[:site_name] = siteGroupMapping.site.display
          site_data_json[:site_ref] = siteGroupMapping.site.site_ref
          site_data_json[:lat] = siteGroupMapping.site.location.geo_lat.to_f
          site_data_json[:lng] = siteGroupMapping.site.location.geo_lng.to_f
          site_data = { kwh: 0, kwhpersqft: 0, cost: 0, costsqft: 0}
          site_data_json[:data] = site_data
          circuit_ids = siteGroupMapping.site.panels.map(&:circuit_ids).flatten.compact
          results = []
          circuit_ids.each do |circuit_id|
            results << EmonDailyData.find_by_sql("select * from emon_daily_data where circuit_id='#{circuit_id}' and as_of_day>='#{beginningDay}' and as_of_day<'#{endingDay}'")
          end
          sum_of_main_power = 0.0;
          results.flatten.each do|result|
            sum_of_main_power =  result['value'].to_f + sum_of_main_power
          end
          kwhpersqft=0
          costsqft = 0
          kwhpersqft = (sum_of_main_power)/siteGroupMapping.site.area_gross_square_foot.to_f  if siteGroupMapping.site.area_gross_square_foot.to_f!=0
          cost = sum_of_main_power * siteGroupMapping.site.location.utility.base_rate.to_f
          costsqft = cost/siteGroupMapping.site.area_gross_square_foot.to_f  if siteGroupMapping.site.area_gross_square_foot.to_f!=0 if kwhpersqft.present? && cost!=0

          site_data = { kwh: sum_of_main_power, kwhpersqft: kwhpersqft, cost: cost, costsqft: costsqft}

          site_data_json[:data] = site_data
          json_data<< site_data_json unless site_data_json.empty?
        end  

      rescue  Exception => e 
        json_data = {"Error" => e.message }
      end
    end

    respond_to do |format|
      format.json { render :json => json_data }
    end

  end

  private

  def sum_of_demand_avg_values 
    redis = Redis.new
    group_id = params[:group_id]
    #db = get_cassandra_connection
    sites = SiteGroup.find(group_id).sites
    demand_sum = 0
    sites.each do|site|
      #if Circuit.where(panel_id: site.id, dis: "Main Power").present?
      site.panels.each do |panel|
        panel.circuits.where(display: "Main Power", active: 1).each do|circuit|
          #results = db.execute("select * from emon_live_data where panel='#{site.site_ref}' and channel='CH-#{circuit.channel_no}' ALLOW FILTERING")
          #results.each do|result|
          #demand_sum = demand_sum + result['avg_power'].to_i
          #end
          #result = redis.hget("panel-#{site.site_ref}-CH-#{circuit.channel_no}", "avg_power")
          demand_sum = demand_sum + result.to_i
        end
        #end
      end
    end
    return demand_sum/1000
  end

  def sum_of_solar_avg_values
    redis = Redis.new
    db = get_cassandra_connection
    solar_sum = 0
    group_id = params[:group_id]
    sites = SiteGroup.find(group_id).sites
    sites.each do|site|
      results = db.execute("select * from min_by_power_produced where site_ref='#{site.site_ref}' and asof_min>=#{(Time.now-3.minute).to_i} limit 1")
      results.each do|result|
        solar_sum = solar_sum + result['value'].to_i
      end
    end
    return solar_sum/1000
  end

  def cassandraDbConnection
    #return CassandraCQL::Database.new('127.0.0.1:9160', {:keyspace => "enos_HGV"})
    cluster = Cassandra.cluster
    session  = cluster.connect("enos_sample")
  end
end
