class Ws::CircuitsController < ApplicationController
  
  before_action :site_ref_check
  
  def get_current_demand_by_site
    redis = Redis.new
    
    site_ref = params[:site_ref]
    
    site = Site.find_by_site_ref(site_ref)
    
    site_data_json = {site_name: site.display}

    db = cassandraDbConnection

    channel_data = {}
    circuit_info = {}
    Circuit.where(panel_id: site.id, input: 0, active: 1).each do|circuit|
    	circuit_info[circuit.display] = circuit.id
	    results = redis.hget("panel-#{site.site_ref}-CH-#{circuit.channel_no}", "avg_power")	
	    channel_data[circuit.display] = results
      #results.each do |result|
	    #	channel_data[circuit.display] = result['avg_power']
	    #end
	  end
    site_data_json[:circuits] = circuit_info
    site_data_json[:data] = Hash[channel_data.sort_by { |k,v| v }.reverse]
    respond_to do |format|
      format.json { render :json => site_data_json }
    end
  end

  def get_fivec_last_month
  	site_data_json = {}
    circuitData = {}
    site = Site.find_by_site_ref(params[:site_ref])
    channel_list = get_all_non_input_channel_names_by_site site
    circuit_ids = site.panels.map(&:circuit_ids).flatten
    db = cassandraDbConnection
    start_time = (Time.now.utc.yesterday - 30.days).beginning_of_day.to_i
    end_time = Time.now.utc.yesterday.beginning_of_day.to_i
    results = EmonDailyData.where(circuit_id: circuit_ids).where('as_of_day > ? AND as_of_day < ?', start_time, end_time)
    #results = db.execute("select * from emon_daily_data where site_ref='#{params[:site_ref]}'")
    results.each do|result|
      circuitData[result.circuit.channel_no.to_s] =  result['value'] if channel_list.has_key?(result.circuit.channel_no.to_s)
    end
    circuitData.delete("Main Power")
    data = Hash[circuitData.sort_by { |k,v| v }.reverse].first 5
    site_data_json[:data] = data.to_h
    respond_to do |format|
      format.json { render :json =>  site_data_json }
    end
  end

  private

  def cassandraDbConnection
  	cluster = Cassandra.cluster
    session  = cluster.connect("enos_sample")
  end
  
  def site_ref_check
  	if  params[:site_ref].nil?
      site_data_json = {"Error" => "Required Parameters: #{'site_ref' if params[:site_ref].nil?}"}
      json_response(site_data_json)
    elsif params[:site_ref].empty?
      site_data_json = {"Error" => "Value Required for: #{'site_ref' if params[:site_ref].empty?}"}
      json_response(site_data_json)
    else
    	if Site.find_by_site_ref(params[:site_ref]).nil?  
      	site_data_json = {"Error" => "Record not found with Site Reference #{params[:site_ref]}"}
        json_response(site_data_json)
      end   
    end
  end

  def get_all_non_input_channel_names_by_site site
    list_of_circuits = {}
    
    if site.site_ref=="HGV10"
      site.panels.each do |panel|
        Circuit.where(panel_id: panel.id, is_producing: 1).each do|circuit|
          list_of_circuits["CH-#{circuit.channel_no}"] = circuit.display
        end
      end
    else
      site.panels.each do |panel|
        Circuit.where(panel_id: site.id, input: 0).each do|circuit|
          list_of_circuits["CH-#{circuit.channel_no}"] = circuit.display
        end
      end
    end
    
    return list_of_circuits
  end
   	
end
