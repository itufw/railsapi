Rails.application.routes.draw do
  resources :projections
  resources :order_types
  mount Bootsy::Engine => '/bootsy', as: 'bootsy'

  root 'sales#sales_dashboard', type: 'merged'
  # post 'admin/update'

  get 'add_task', to: 'task#add_task'
  get 'local_calendar', to: 'calendar#local_calendar'
  get 'add_note', to: 'activity#add_note'
  get 'add_activity', to: 'activity#add_activity'
  get 'activity_edit', to: 'activity#activity_edit'
  # Google
  get '/redirect', to: 'calendar#redirect', as: 'redirect'
  get '/callback', to: 'calendar#callback', as: 'callback'
  get '/calendars', to: 'calendar#calendars', as: 'calendars'

  get '/fetch_calendar', to: 'calendar#fetch_calendar', as: 'fetch_calendar'
  get '/fetch_calendar_date', to: 'calendar#fetch_calendar_date', as: 'fetch_calendar_date'
  get '/event_check_offline', to: 'calendar#event_check_offline', as: 'event_check_offline'
  get '/translate_events', to: 'calendar#translate_events'
  get '/event_censor', to:'calendar#event_censor'
  get '/calendar/local_calendar', to: 'calendar#local_calendar'

  get "/new_order_form" => 'order#new_order_form', as: "new_order_form"
  
  get '/fetch_order_detail', to: 'order#fetch_order_detail', as: 'fetch_order_detail'
  get '/fetch_last_products', to: 'status#fetch_last_products', as: 'fetch_last_products'
  get '/fetch_product_selected', to: 'product#fetch_product_selected', as: 'fetch_product_selected'
  get '/fetch_group_detail', to: 'admin#fetch_group_detail', as: 'fetch_group_detail'
  get '/fetch_add_item', to: 'admin#fetch_add_item', as: 'fetch_add_item'
  get '/fetch_remove_item', to: 'admin#fetch_remove_item', as: 'fetch_remove_item'

  get '/fetch_lead', to: 'lead#fetch_lead', as: 'fetch_lead'
  get '/fetch_product_details', to: 'product#fetch_product_details', as: 'fetch_product_details'
  get '/verify_abn', to: 'credit#verify_abn', as: 'verify_abn'
  get '/credit_list', to: 'credit#credit_list', as: 'credit_list'

  get '/rails/mailers' => 'rails/mailers#index'
  get '/rails/mailers/*path' => 'rails/mailers#preview'

  get '/activity/add_note', to: 'activity#add_note'
  get '/activity/add_activity', to: 'activity#add_activity'
  get '/activity/daily_products', to: 'activity#daily_products'

  post 'add_task', to: 'task#task_record'
  post 'local_calendar', to: 'calendar#local_calendar'
  post 'add_note', to: 'activity#add_note'
  post 'contact/create_contact', to: 'contact#contact_creation'
  post 'contact/edit_contact', to: 'contact#contact_edition'

  # this needs to be replaced sometime
  match ':controller(/:action(/:id))', via: %i[get post patch]

  resources :calendar do
    get :autocomplete_customer_tag_name, on: :collection
  end

  resources :contact do
    get :autocomplete_customer_actual_name, on: :collection
  end

  resources :product do
    get :autocomplete_product_name, on: :collection
  end

  resources :activity do
    get :autocomplete_product_name, on: :collection

    # TO BE DEPRECATED
    get :autocomplete_beer_name, on: :collection

    # TO BE DEPRECATED
    get :autocomplete_beer_ws, on: :collection

    # TO BE DEPRECATED
    get :autocomplete_product_ws, on: :collection
    
    # TO BE DEPRECATED
    get :autocomplete_product_retail, on: :collection

    # TO BE DEPRECATED
    get :autocomplete_product_wholesale, on: :collection

    # new route to be a replacement of the deprecated routes above
    get :autocomplete_products, on: :collection
    
    
    get :autocomplete_product_no_ws_name, on: :collection
    get :autocomplete_product_no_vintage_name, on: :collection
    

    # TO BE DEPRECATED
    get :autocomplete_customer_actual_name, on: :collection

    get :autocomplete_customer_retail, on: :collection
    get :autocomplete_customer_wholesale, on: :collection

    get :autocomplete_contact_name, on: :collection
    get :autocomplete_customer_lead_actual_name, on: :collection
    get :autocomplete_staff_nickname, on: :collection
    get :autocomplete_sale_rate_term_name, on: :collection
    get :autocomplete_producer_name, on: :collection
  end

  # The priority is based upon order of creation: first created ->
  # highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource
  # route (maps HTTP verbs to controller actions automatically):
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
