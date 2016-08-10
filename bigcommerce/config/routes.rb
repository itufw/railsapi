Rails.application.routes.draw do
  get 'access/login'

  get 'models/orders'

  get 'models/customers'

  get 'models/products'

  get 'sales/view_sales_dashboard'

  get 'sales/view_daily_orders_for_rep'

  get 'sales/view_weekly_orders_for_rep'

  get 'sales/view_overall_daily_orders'

  get 'sales/view_orders_for_customer'

  get 'sales/view_products_for_orderid'

  get 'sales/view_orders_for_product_and_customer'

  get 'sales/view_orders_for_product_and_status'

  get 'sales/view_orders_by_status'

  get 'sales/view_product_stats_for_customer'

  get 'sales/view_customer_stats_for_product'

  get 'sales/view_orders_for_product'


  get 'admin/index'

  get 'admin/update'

  get 'admin/import_from_csv'
  
  get 'admin/scrape'

  #root 'sales#view_sales_dashboard'
  #post 'admin/update'

  match ':controller(/:action(/:id))', via: [:get, :post]



  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

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
