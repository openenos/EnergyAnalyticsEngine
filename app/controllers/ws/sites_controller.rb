require 'yaml'

class Ws::SitesController < ApplicationController
  
  before_action :site_ref_check

  public

  def get_live_data_by_site
  	#raise params.inspect
  	redis = Redis.new
  	site_data_json = {}
    site_ref = params[:site_ref]
    
    site = Site.find_by_site_ref(site_ref)

    site_data_json = {site_name: site.display}
    
    #if Circuit.where(panel_id: site.id, dis: "Main Power").present?
    
    #Circuit.where(panel_id: site.id, input: 1, active: 1).each do|circuit|

      #results = db.execute("select * from emon_live_data where panel='#{site.site_ref}' and channel='totalPower' ALLOW FILTERING")
	  result = redis.hmget("panel-#{site_ref}-totalPower", "avg_power", "max_power", "total_power")
    #raise result.inspect
    values = {avg_power: result[0].to_i/1000.0, max_power: result[1].to_i/1000.0, total_power: result[2]}
      #raise results.inspect
    #results.each do|result|
      #values = {avg_power: result['avg_power']/1000.0, max_power: result['max_power']/1000.0, total_power: result['total_power']}
      site_data_json = site_data_json.merge(values)
      #site_data_json[circuit.display.to_s] = values
    #end
      #end
    #end
 
	  respond_to do |format|
	    format.json { render :json => site_data_json }
	  end
  end

  def solar_data_by_site
  	
  	site_data_json = {}  
    site_ref = params[:site_ref]
  
    site = Site.find_by_site_ref(site_ref)
     

    has_solar = site.panels.first.circuits.where(input: 1, active:1).where.not(display: "Main Power").count > 0 ?  1 :  0
    
    site_data_json = {site_name: site.display}
    db = cassandraDbConnection

    results = db.execute("select * from min_by_power_produced where site_ref='#{site.site_ref}' and asof_min>=#{Time.now.beginning_of_day.utc.to_i} and asof_min<#{Time.now.end_of_day.utc.to_i} ALLOW FILTERING")      
    #raise results.inspect
    soFarTodayValue  = 0
    currentValue = 0 
    solr_count = 0
    results.each do|result|
      #raise result['value'].inspect
      currentValue = result['value'] if solr_count == 0
      soFarTodayValue += result['value']
      solr_count += 1
    end
    
    values = {soFarTodayValue: ((soFarTodayValue/60)/1000.0).round, currentValue: (currentValue/1000).round, has_solar: has_solar} 
    
    site_data_json = values    
  
    respond_to do |format|
      format.json { render :json => site_data_json }
    end

  end     

  def get_weather
    json_data = {}
    
    weather_ref = Site.find_by_site_ref(params[:site_ref]).location.postal_code.weather_ref

    weather = YAML.load_file('config/weather.yml')
  	$weather = weather[Rails.env]

    w_api = Wunderground.new($weather['api_key'])
 
    result = w_api.conditions_for("pws:#{weather_ref.to_s}")
    #country = result['current_observation']['observation_location']['country']
    #city = result['current_observation']['observation_location']['city']
    
    unless result['current_observation'].nil?
	    image = result['current_observation']['icon_url']
	    status = result['current_observation']['weather']
	    temp_f = result['current_observation']['temp_f']
	    wind_string = "From the #{result['current_observation']['wind_dir']} at #{result['current_observation']['wind_mph']} MPH "
	    relative_humidity = result['current_observation']['relative_humidity']
	    
	    json_data = {image: image, status: status, temp_f: temp_f, wind_string: wind_string, relative_humidity: relative_humidity}
	    
	    forecast = JSON.load(open("http://api.wunderground.com/api/#{api_key}/forecast/q/pws:#{weather_ref.to_s}.json"))
	    
	    forecast_data = []
	    
	    (1..3).each do|week_day|
	      day_data = { day: forecast["forecast"]["simpleforecast"]["forecastday"][week_day]["date"]["weekday"],
	      min: forecast["forecast"]["simpleforecast"]["forecastday"][week_day]["low"]["fahrenheit"],
	      max: forecast["forecast"]["simpleforecast"]["forecastday"][week_day]["high"]["fahrenheit"] }
	      forecast_data << day_data
	    end
	    
	    json_data['forecast'] = forecast_data
    
    end
    
    respond_to do |format|
      format.json { render :json => json_data }
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
  

  def json_response(site_data_json)
    respond_to do |format|
      format.json { render :json => site_data_json }
    end
  end

end
