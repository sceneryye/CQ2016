#encoding:utf-8
require 'httpclient'
Modengke::Application.routes.draw do

  mount WeixinRailsMiddleware::Engine, at: "/"

  root :to=>"home#index",:constraints=>{ :subdomain=>/^(www)?$/ }
  get 'blank'=>"home#blank"
  get 'home'=>"home#index1"

  resource :weixin do
    member do
        get 'callback'
    end
  end

  scope :module => "memberships" do
    resources  :cards do
      collection do
        get 'recharge'
        get 'topup'

        get 'bank'
        post 'member_card'

        get 'rebates'
        get 'withdrawals'
        get 'apply_withdrawal'
        get 'tradings'

        post 'login'
        post 'pay'

        get 'subcards'
      end
    end

    resources  :member_cards

    resource :profile do
      member do
        get 'password'
        put 'modify_password'
      end
    end

    resource :member do
      member do
        get 'orders'
        get 'shares'
        get 'coupons'
        get 'cards'
        get 'advance'
        get 'after_sale'
        get 'favorites'
        get 'goods'
        get 'inventorys'
        get 'inventorylog'
        post 'export_inventory'
        post 'coupon_check'
      end
    end


    resources :aftersales do
      get 'instruction', :on=>:collection
    end

    resource :validation do
      get 'email'
      get 'mobile'
      post 'verify'
      post 'sent'
      get 'verify_email'
    end

    resources :member_addrs do
        get "mobile"  ,:on=>:collection
        get 'new_memberaddr_add' ,:on=>:collection
    end

  end

  resources :pages, :only=>[:show]

  namespace :auth do
    resources :accounts
    resources :weixin do
      get 'callback',:on=>:member
    end
  end

  resources :sessions

  get 'register'=>'users#new'
  resources :users do
    get 'forgot_password', :on=>:collection
    post 'send_reset_password_instruction', :on=>:collection
    get 'reset_password',:on=>:collection
    post 'search', :on=>:collection
    post 'change_password',:on=>:collection
    post 'update' ,:on=>:member
  end

  get 'auto_login'=>"sessions#auto_login"
  get 'login'=>"sessions#login"
  post 'login'=>"sessions#create"
  get 'logout'=>"sessions#destroy"
  get 'topmenu'=>"home#topmenu"

  scope :module=> "events" do
    resources :user_survey, :controller=>"survey" do
      post "add_mobile", :on=>:collection
    end
  end

  namespace :events do
    resources :applicants
  end

  resources :events


  get 'admin'=>'admin/sessions#new'

  namespace :admin do

    # subdomain = nil
    # subdomain = "www" if Rails.env == "production"
    # constraints :subdomain => subdomain do
    get 'logout'=>'sessions#destroy'
    resources :tracks do
      get :pages,:on=>:collection
    end

    resources :carts

    resources :wechat do
      get :menu,:on=>:collection
      get :menu_edit,:on=>:collection
      get :followers, :on=>:collection
      get :followers_import, :on=>:collection
      get :follower_renew,:on=> :collection
      get :groups, :on=>:collection
      get :batch_sending, :on=>:collection
      get :weixin,:on=>:collection
    end
    resources :resources
    resources :permissions do

    end
    resources :suppliers do
      get 'update_state',:on=>:collection
    end

    resources :sessions
    resources :coupons
    resources :goods_cats do
      get :create_top,:on=>:collection
      get :toggle_future,:on=>:member
      get :toggle_agent,:on=>:member
      get :toggle_sell,:on=>:member
      post :save_top,:on=>:collection
    end
    resources :goods_types do
      put :updateType,:on=>:member
    end
    resources :goods_labels do
      put :updateLabel,:on=>:member
      get :createLabel,:on=>:collection
    end

    resources :brand_adms do
      get 'toggle', :on=>:member
      put 'order', :on=>:member
      put 'reco', :on=>:member
      get :delete
      put :update_brand,:on=>:member
    end

    resources :goods do
      post "export", :on=>:collection
      post "import", :on=>:collection
      post "remove_spec_item",:on=>:member
      get "add_spec_item",:on=>:member
      get "spec",:on=>:member
      put "update_spec",:on=>:member
      get 'select_goods',:on=>:collection
      get 'collocation',:on=>:member
      get 'set_suits',:on=>:member
      get 'cancel_suits',:on=>:member
      post 'create_collocation',:on=>:collection
      get 'search', :on=>:collection
      get 'select_gifts',:on=>:collection
      put 'batch',:on=>:collection
      get 'select_all',:on=>:collection

      get :toggle_future,:on=>:member
      get :toggle_agent,:on=>:member
      get :toggle_sell,:on=>:member
    end
    resources :spec_items

    resources :images do
      post "mark", :on=>:collection
      post "rollback",:on=>:collection
      post "refresh",:on=>:collection
    end
    resources :articles do
      post 'set_position',:on=>:collection
    end
    resources :topics do
      post 'set_position',:on=>:collection
      post 'published_at',:on=>:member
    end
    resources :pages
    resources :inventory_logs

    resources :members do
      post "export",:on=>:collection
      post "column_reload",:on=>:collection
      post "send_sms",:on=>:collection
      post "send_sms2",:on=>:collection
      get :info,:on=>:member
      put :updateInfo,:on=>:member
    end

    resources :card_tradings

    resources :rebates

    resources :withdrawals do

      member do
        get :pay
        get :rebates
        get :cancel
      end
    end

    resources :cards do
      member do
        get 'buy'
        get 'use'
        get 'edit_user'
        get 'edit_pay'
        get 'logs'
        put "untag"
        put "cancel_order"
        get "allinpay"
        get 'active'
        post 'topup'
        post 'card_status'
        post 'pay_with_pwd'
        get 'reset_password'
        post 'get_info'
        get 'get_trade_log'
        post 'pay_to_client'
      end

      collection do
        get "trading_log"
        post 'topup'
        post 'pay_with_pwd'
        post 'reset_password'
        post 'get_info'
        get 'get_trade_log'
        post 'pay_to_client'
      end

      post 'import', :on=>:collection
      post "export",:on=>:collection
      get "tag",:on=>:collection
    end

    resources :users do
      get 'search',:on=>:collection
      post 'newuser',:on=>:collection
      put 'send_sms_code',:on=>:member
      put 'buy_card',:on=>:member
      put 'use_card',:on=>:collection
      get 'select', :on=>:member
      put 'validate_mobile',:on=>:member
    end

    resources :member_cards

    resources :tag_exts

    resources :configs

    resources :labels

    resources :emails do
      get 'send_all',:on=>:collection
    end

    resources :categories

    resources :applicants

    resources :events do
      get 'applicants',:on=>:member
    end

    resources :homes

    resources :promotions

    resources :new_coupons do
      get 'download', :on=>:member
      get  'select_coupons', :on=>:collection
    end

    resources :user_coupons

    resources :orders do
      collection do
        get 'search'
        post 'export'
        put 'batch'
      end

      member do
        get 'detail'
        get 'pay'
        post 'dopay'
        get 'delivery'
        post 'dodelivery'
        get 'print_order'
        get 'print_preparer'
        get 'reship'
        post 'doreship'
        get 'refund'
        post 'dorefund'
        get :comment
        patch :update_memo
      end
    end

    resources :static_pages
    resources :footers

    resources :metas

    resources :specifications

    resources :tags

    resources :offline_coupons do
      get 'downloads',:on=>:member
    end

    resources :virtual_goods do
      post 'import', :on=>:collection
    end

    resources :payment_logs

    # end
  end

  scope :module => "store" do

    get 'search' => "search#index", :as=> :search
    get 'coupon_goods' =>"goods#coupon_goods", :as=>"goods" ,:controller=>"goods"

    resources :products, :as=>"goods", :controller=>"goods" do
      # get 'newin',:on=>:collection
      get 'newest',:on=>:collection
      put 'fav',:on=>:member
      put 'unfav',:on=>:member
      get 'price',:on=>:member
      get 'more',:on=>:collection
      get 'suits', :on=>:collection
      get 'more_suits', :on=>:collection

    end

    resources :suppliers

    resources :coupons, :controller=>"offline_coupons" do
      post 'download',:on=>:member
    end

    resources :vgoods, :controller=>"virtual_goods",:only=>[:index,:show]
    post 'cart/add'=>"cart#add",:as=>:add_to_cart

    resources :cart do
      post 'add',:on=>:collection
    end
    resources :brands,:only=>[:index,:show]
    resources :users
    resources :vshop
    resources :country, :as=>"countries", :controller=>"countries"
    resources :gallery, :as=>"cats", :controller=>"cats"


    resources :goods,  :as=>"orders", :controller=>"orders" do
      member do
        get :goods
      end
    end

    get 'share' =>"orders#share"


    resources :orders, :except=>[:index] do
      member do
        post :pay
        get :detail
        get :goods

      end

      collection do
        post 'destroyaddr'
        get 'check_coupon'
        get  'new_mobile'
        get 'new_mobile_addr'
        get 'departure'
        post 'arrival'
        get 'arrival'
        get 'index_mobile'
        get 'share_order'   ###推荐订单
        get 'addr_detail'
        get 'new_mobile_addr'
        post 'edit_addr'
        post 'xiugai_addr'
      end
    end

    resources :payments do

      collection do
        post 'add_advance'
        get 'callback'
        get 'pay'
        # match ':adapter/notify'=>"payments#notify", :as=>"notify" , :via => [:get]
        # match ':adapter/callback'=>"payments#callback", :as=>"callback", :via => [:get]
      end

      member do
       # get 'pay'
        match ':adapter/notify'=>"payments#notify", :as=>"notify", :via => [:get]
        match ':adapter/callback'=>"payments#callback", :as=>"callback", :via => [:get]
        if Rails.env == 'development'
          get 'test_notify'
          get 'test_callback'
        end
      end
    end
  end

  scope '(:agent)',:module => "store" do
    resources :products, :as=>"goods", :controller=>"goods" do
      get 'newin',:on=>:collection
      get 'newest',:on=>:collection
      put 'fav',:on=>:member
      put 'unfav',:on=>:member
      get 'price',:on=>:member
    end

    # post 'cart/add'=>"cart#add",:as=>:add_to_cart
    resources :cart do
      post 'add',:on=>:collection
    end

    resources :users

  end


  resources :comments,:only=>[:create]

  mount Ckeditor::Engine => '/ckeditor'



  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view', :via => [:get]
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
