class Ws::SiteChannelsController < ApplicationController

before_action :site_ref_check

	def day_data_by_site_channel
    site_ref = params[:site_ref]
    begin
	    site = Site.find_by_site_ref(site_ref)
	    givenChannel = Circuit.find(params[:channel]).channel_no

	    given_date =  params[:date] # format "02-06-2014"

	    beginningDay = (given_date.to_datetime.to_time.utc + params[:offset].to_i.minute).to_i
	    endingDay = beginningDay + 86400

	    site_data_json = {site_name: site.display} 

	    channel_data = {}
	    channel_name=""
	    arr_keys = []
	    arr_values = []
	    day_data = []

	    site.panels.map(&:circuits).flatten.each do |circuit|
        if circuit.input == 0 && circuit.active == 1  && circuit.channel_no == givenChannel
	      	results = EmonDailyData.find_by_sql("select * from emon_min_by_data where circuit_id='{circuit.id}' and as_of_day>=#{beginningDay} and as_of_day<#{endingDay} ALLOW FILTERING")
	      	channel_name = circuit.display

		      results.each do|result|
		        day_data << [result['as_of_day'].to_i*1000, result['value']]
		      end
		    end  
	    end
	  	site_data_json[:data] = day_data
    rescue Exception => e 
      site_data_json = {"Error" => e.message }
    end
    respond_to do |format|
      format.json { render :json => site_data_json }
    end
  
  end

	def prevday_data_by_site_channel
    site_ref = params[:site_ref]
    begin
	    site = Site.find_by_site_ref(site_ref)

	    given_date =  (params[:date].to_datetime)-1.day # format "02-06-2014"

	    beginningDay = (given_date.to_time.utc + params[:offset].to_i.minute).to_i
	    endingDay = beginningDay + 86400

	    givenChannel = Circuit.find(params[:channel]).channel_no

	    db = cassandraDbConnection
	    site_data_json = []   
	    
	    channel_data = {}
	    arr_keys = []
	    arr_values = []
	    day_data=[]
	    
	    site.panels.map(&:circuits).flatten.each do |circuit|
      
        if circuit.input == 0 && circuit.active == 1  && circuit.channel_no == givenChannel

		      results = EmonDailyData.find_by_sql("select * from emon_min_by_data where circuit_id='{circuit.id}' and as_of_day>=#{beginningDay} and as_of_day<#{endingDay} ALLOW FILTERING")
		    
		      results.each do|result|
		        site_data_json << [(result['as_of_day'].to_i*1000)+86400000, result['value']]
		      end
		    
		    end
		      
	    end
    rescue Exception => e 
      site_data_json = {"Error" => e.message }
    end
    
    respond_to do |format|
      format.json { render :json => site_data_json }
    end
  
  end

	def dayDataBySiteAndChannel
	  site_ref = params[:site_ref]	
	  begin
	    site = Site.find_by_site_ref(site_ref)

	    givenChannel = params[:channel]
	    given_date =  params[:date] # format "02-06-2014"
	    beginningDay = (Time.now - 24.hour).utc.to_i
	    endingDay = Time.now.utc.to_i

	    db = cassandraDbConnection
	    site_data_json = {}
	        

	    channel_data = {}
	    channel_name=""
	    arr_keys = []
	    arr_values = []
	    day_data = []

	    site.panels.map(&:circuits).flatten.each do |circuit|
      
        if circuit.input == 0 && circuit.active == 1  && circuit.channel_no == givenChannel

		      results = EmonDailyData.find_by_sql("select * from emon_min_by_data where circuit_id='{circuit.id}' and as_of_day>=#{beginningDay} and as_of_day<#{endingDay} ALLOW FILTERING")
		      site_data_json[:channel] = circuit.display
		      channel_name = circuit.display

		      results.each do|result|
		        day_data << [result['as_of_day'].to_i*1000, result['value']]
		      end

		    end  
	    end

	    site_data_json[:data] = day_data
	  rescue Exception => e 
	    site_data_json = {"Error" => e.message }
	  end
	  
	  respond_to do |format|
	    format.json { render :json => site_data_json }
	  end
	
	end
  

  def week_data_by_site_channel
    site_ref = params[:site_ref]
    begin
	    site = Site.find_by_site_ref(site_ref)
	    givenChannel = Circuit.find(params[:channel]).channel_no

	    given_date =  params[:date] # format "02-06-2014"
	    
	    beginningDay = ((given_date.to_datetime - 7.day).to_datetime.beginning_of_day.to_time).utc.to_i
	    endingDay = (given_date.to_datetime.end_of_day.to_time).utc.to_i

	    site_data_json = {site_name: site.display}    
	      
	    channel_data = {}
	    arr_keys = []
	    arr_values = []
	    day_data = []

	    site.panels.map(&:circuits).flatten.each do |circuit|
      
        if circuit.input == 0 && circuit.active == 1  && circuit.channel_no == givenChannel
	        	
		      results = EmonDailyData.find_by_sql("select * from emon_hourly_data where circuit_id='{circuit.id}' and as_of_day>=#{beginningDay} and as_of_day<=#{endingDay} ALLOW FILTERING")
		    
		      results.each do|result|
		        day_data << [result['asof_hr'].to_i*1000, result['value']]
		      end
		    
		    end  
	    
	    end
	   	site_data_json['data'] = day_data
    rescue Exception => e 
      site_data_json = {"Error" => e.message }
    end

    respond_to do |format|
      format.json { render :json => site_data_json }
    end

  end
  
  def month_data_by_site_channel
  	site_ref = params[:site_ref]
    begin
	    site = Site.find_by_site_ref(site_ref)
	    givenChannel = Circuit.find(params[:channel]).channel_no

	    given_date =  params[:date] # format "02-06-2014"
	    
	    beginningDay = (given_date.to_datetime.beginning_of_month.to_time).utc.to_i
	    endingDay = (given_date.to_datetime.end_of_month.to_time).utc.to_i
	    
	    db = cassandraDbConnection
	    site_data_json = {site_name: site.display}    
	    channel_data = {}
	    arr_keys = []
	    arr_values = []
	    day_data = []
	    
	    site.panels.map(&:circuits).flatten.each do |circuit|
      
        if circuit.input == 0 && circuit.active == 1  && circuit.channel_no == givenChannel

		      results = EmonDailyData.find_by_sql("select * from emon_hourly_data where circuit_id='{circuit.id}' and as_of_day>=#{beginningDay} and as_of_day<=#{endingDay} ALLOW FILTERING")
		 
		      results.each do|result|
		        day_data << [result['asof_day'].to_i*1000, result['value']]
		      end

		    end  

	    end
	    site_data_json['data'] = day_data
    rescue Exception => e 
      site_data_json = {"Error" => e.message }
    end

    respond_to do |format|
      format.json { render :json => site_data_json }
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

end
