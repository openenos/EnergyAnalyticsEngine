Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'


  namespace :ws, defaults: {format: 'json'} do
    get '/getAllGroups' => 'site_groups#get_all_groups'
    get '/getUsageByGroup' => 'site_groups#get_usage_by_group'
    get '/getSiteByGroup' => 'site_groups#get_site_by_group'
    get '/getDemandByGroup' => 'site_groups#get_demand_by_group'
    get '/usageByGroup' => 'site_groups#usage_by_group'
    get '/currentDemandByGroup' => "site_groups#current_demand_by_group"
    get '/solarPowerByGroup' => "site_groups#solar_power_by_group"
    get '/utilityPower' => "site_groups#utility_power"

    get '/getLiveDataBySite' => "sites#get_live_data_by_site"
    get '/solarDataBySite' => "sites#solar_data_by_site"
    get '/getWeather' => "sites#get_weather"
    get '/getAllChannelsListBySiteref' => "sites#get_all_channels_list_by_siteref"
    get '/getCurrentDemandBySiteChannel' => "sites#get_current_demand_by_site_channel"

    get '/getCurrentDemandBySite' => "circuits#get_current_demand_by_site"
    get '/getFivecLastMonth' => "circuits#get_fivec_last_month"
    get '/powerPrediction' => "circuits#power_prediction"
  end

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
