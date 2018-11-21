require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  match "/404", :to => "exceptions#not_found", :via => :all
  post 'user_token' => 'user_token#create'
  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end
  post "/graphql", to: "graphql#execute"

  authenticate :user, lambda { |u| u.space == 'space_admin' } do
    mount Sidekiq::Web => '/sidekiq'
  end

  devise_for :users, :controllers => {:registrations => "registrations", :passwords => "passwords", :sessions => "sessions", :invitations => "invitations"}

  root "login#index"

  # Temporary Sample URL for checking asset pipeline
  resources :ui_sample

  namespace :admin do
    resources :imports do
    end
    resources :impersonation do
      collection do
        post :impersonate
        post :order
      end
    end
    resources :notifications do
      collection do
        get :table
        post :search
      end
      member do
        get :remove
      end
    end
    resources :searches do
      collection do
        post :quick
      end
    end
    resources :dashboard do
      collection do
        get :activity
      end
      member do
        post :confirm_order
        post :cancel_order
        post :confirm_app
        post :cancel_app
        get :cancel_popup
        get :byo
        get :order_food
        post :update_byo
        post :activate_user
      end
    end
    resources :users do
      collection do
        resources :notifications, as: :user_notifications, module: :users do
          collection do
            get :recent
          end
        end
        get :password
        patch :update_password
        get :table
        post :search
        get :ping # Actioncable ping test
        get :rake
        get :office
        get :restaurant
      end
      member do
        get :reinvite
        post :activate
        post :deactivate
        post :impersonate
      end
      resources :preferences, module: :users do
        collection do
          get :edit_preferences
          post :update_preferences
        end
      end
    end

    resources :offices do
      resources :policies, module: :offices
      resources :sales_reps, module: :offices do
        member do
          post :delete
        end
      end
      resources :users, module: :offices do
        member do
          post :delete
        end
        collection do
          get :index
        end
      end
      resources :providers, module: :offices do
        member do
          post :delete
        end
      end
      resources :contacts, module: :offices do
        member do
          post :delete
        end
      end
      resources :appointments, module: :offices do
        collection do
          get :list
        end
      end
      resources :orders, module: :offices do

      end
      resources :slots, module: :offices do
        collection do
          get :copy
          post :create_copy
        end
        member do
          post :delete
          post :activate
          post :deactivate
        end
      end
      collection do
        get :table
        post :search
        post :report
      end
      member do
        get :edit_office_exclude_dates
        post :activate
        post :deactivate
        post :delete
      end
    end
    resources :providers do
      resources :slots, module: :providers do
        collection do
          get :copy
          post :create_copy
        end
        member do
          post :delete
        end
      end
      collection do
        get :table
      end
    end
    resources :sales_reps, path: "reps" do
      resources :appointments, module: :sales_reps
      resources :offices, module: :sales_reps
      resources :notifications, module: :sales_reps
      resources :contacts, module: :sales_reps do
        collection do
          get :edit_preferences
          post :update_preferences
          post :delete
        end

      end
      resources :payments, module: :sales_reps do
        member do
          post :delete
        end
      end
      resources :partners, module: :sales_reps, only: [:index, :new, :create, :delete] do
        member do
          post :delete
        end
      end
      resources :drugs, module: :sales_reps, only: [:index, :new, :create, :delete] do
        member do
          post :delete
        end
      end
      resources :orders, module: :sales_reps
      resources :rewards, module: :sales_reps
      collection do
        get :table
        post :search
        post :report
      end
      member do
        post :activate
        post :deactivate
        post :delete
        get :reinvite
      end
    end
    resources :restaurants do
      resources :orders, module: :restaurants do
        member do
          post :confirm
          post :cancel
        end
      end
      resources :users, module: :restaurants
      resources :contacts, module: :restaurants do
        member do
          post :delete
        end
      end
      resources :pay_methods, module: :restaurants do
        member do
          get :activate
          post :delete
        end
      end
      resources :payments, module: :restaurants
      resources :menus, module: :restaurants do
        member do
          post :activate
          post :deactivate
          post :delete
          get :find_items
          post :add_item
          post :update
          post :export
        end
        collection do
          get :menu_setup
        end
      end
      resources :menu_items, module: :restaurants do
        member do
          get :activate
          post :activate
          post :remove
          post :deactivate
          post :delete
          get :upload_asset
          post :complete_upload_asset
        end
        collection do
          get :menu_items_setup
        end
      end
      resources :lunch_packs, module: :restaurants do
        member do
          get :activate
          get :deactivate
          post :delete
        end
      end
      collection do
        get :table
        post :search
        post :report
      end
      member do
        post :activate
        post :deactivate
        post :delete
        get :upload_asset
        get :upload_partial
        post :complete_upload_asset
        get :preferences
        get :registration
        post :update
      end
    end
    resources :companies do
      collection do
        get :table
        post :search
      end
      member do
        post :activate
        post :deactivate
      end
    end
    resources :drugs do
      collection do
        get :table
        post :search
      end
    end
    resources :rewards do
      collection do
        get :table
        get :edit
        get :edit_points
        post :search
      end
    end
    resources :payments do
      collection do
        get :table
      end
    end
    resources :orders do
      collection do
        get :table
        post :search
        post :report
      end
      member do
        get :remove_item
        get :select_item
        post :send_receipt
        post :add_item
        post :decline
        post :confirm
        post :manual_complete
      end
    end
    resources :order_reviews do
      collection do
        get :table
        post :search
        post :report
      end
    end
    resources :appointments do
      member do
        get :cancel_popup
        get :edit_notes
        get :confirm_popup
        post :cancel
        post :confirm
      end
      collection do
        get :table
        post :report
        post :search
      end
    end
    resources :office_device_logs, path: 'lunchpads' do
      collection do

      end
    end

    resources :tools, only: [:index]
    namespace :tools do
      resources :cuisines do
        member do
          post :delete
        end
      end
      resources :diet_restrictions do
        member do
          post :delete
        end
      end
      resources :holiday_exclusions, path: 'holidays' do
        member do
          post :delete
        end
      end
      resources :merge_reps do
        collection do
          get :table
          post :search
          post :report
          post :merge
        end
      end
    end

    # Notification Management
    resources :notification_events do
        member do
            post :activate
            post :deactivate
        end
      resources :notification_event_recipients, path: 'recipients', module: :notification_events do
        member do
          get :test #Send a test notification
          post :send_test
          post :reset_defaults
          post :activate
          post :deactivate
        end
      end
      collection do
        get :table
      end
    end

    root "users#index"
  end

  resources :welcome do
  end

  namespace :restaurant do
    namespace :account do
      resources :bank_accounts do
        member do
          post :delete
          post :update
        end
        collection do
          get :edit
        end
      end
      resources :restaurant_pocs do
        member do
          post :delete
          post :update
        end
        collection do
          get :edit
        end
      end
    end
    resources :orders do
      member do
        post :update
        post :update_driver
        post :update_confirmation
        get :detail
        post :download
      end
      collection do
        get :index
        get :history
        get :driver_info
        get :filter_orders
      end
    end
    resources :preferences do
      member do
        post :update
        patch :update_preferences
        put :update_availabilities
        put :update_exclusions
        put :update_delivery_distance
      end
      collection do
        get :index
        get :edit
      end
    end
    resources :restaurant_exclude_dates do
      collection do

      end
    end
    resource :delivery_distance do
      collection do
        get :index
      end
    end
    resources :menus do
      collection do
        get :index
      end
    end
    resources :account do
      collection do
        get :reviews
        get :payment_information
        get :payments
        get :contact_information
        get :faq
        get :select_restaurant
        get :terms
        get :notifications
        get :summary
        get :privacy_policy
        get :change_password
        get :show_delete_account
        get :show_contact_us
        post :update_password
        post :delete_account
        post :update
        post :update_notification_prefs
        post :end_impersonation
      end
      member do
        patch :update_pocs
        patch :set_current_restaurant
      end
    end
    resources :restaurant_availabilities do
      collection do

      end
    end
    resources :notifications do
      member do
        post :remove
      end
      collection do
        get :index
        get :dropdown
      end
    end

  end

  #used in office manager
  namespace :office do
    resources :calendars do
      collection do
        get :current
      end
    end
    resources :slots do
      collection do
        post :filter_slots
        get :copy
        post :create_copy
      end
      member do
        post :delete
      end
    end
    resources :office_exclude_dates do
      collection do

      end
    end
    resources :appointments do
      member do
        post :cancel
        post :cancel_recommendation
        patch :confirm
        get :recommendation
        get :complete
        get :edit_recommendation
        get :select_restaurant
        get :select_food
        post :filter_restaurants
        post :sort_restaurants
        get :notify_standby
      end
      collection do
        post :exclude
      end

    end
    resources :orders do
      collection do
        get :menu
      end
      member do
        post :review
        get :select_item
        get :remove_item
        get :edit_item
        get :complete
        post :add_item
        patch :update_item
        get :payment
        patch :save_payment
        post :cancel
        get :confirm
        post :complete_order
        patch :complete
        post :download
        post :undo_changes
      end
    end
    resources :providers do
      member do
        get :exclude_dates
        post :remove
      end
      collection do
        get :specialties
      end
    end
    resources :restaurants do
      member do
        get :reviews
      end
    end
    resource :account, controller: :account do
      collection do
        get :index
        get :change_password
        patch :update_password
        get :show_delete_account
        post :delete_account
        post :end_impersonation
      end
    end
    namespace :account do
      resources :payment_methods do
        collection do
        end
        member do
          post :delete
          post :set_default
        end
      end
    end
    resources :notifications do
      member do
        post :remove
      end
      collection do
        get :index
        get :dropdown
      end
    end
    resources :preferences, path: "/" do
      member do
        patch :update
        put :update_exclusions
      end
      collection do
        get :appointments_until
        get :show_rep_sample
        get :policies
        get :notification_preferences
        get :directory
        get :providers
        get :rep_past_appointments
        get :show_rep
        post :search
        get :faq
        get :policies_modal
        post :update_notification_preferences
      end
    end
  end

  namespace :rep do
    namespace :profile do
      resources :partners do
        member do
          post :delete
          post :reject
          post :accept
        end
        collection do
          post :create
          get :partner_request
        end
      end
      resources :payment_methods do
        member do
          post :delete
          post :set_default
          post :update
        end
        collection do
          get :edit
        end
      end
    end
    resources :profile, only: [:index, :information, :budget, :notifications] do
      member do
        post :complete_upload_asset
      end
      collection do
        get :information
        get :financial_info
        get :partner
        get :rewards
        get :faq
        get :general_information
        get :notifications
        get :summary
        get :change_password
        get :show_delete_account
        get :show_contact_us
        get :office_budgets
        post :update_password
        post :update_notification_prefs
        put :update_office
        get :upload_asset
        post :update
        post :delete_account
        post :end_impersonation
        post :update_budgets
      end
    end
    resources :providers do
      collection do
        post :search
      end
    end
    resources :offices do
      collection do
        post :search
        get :show_refer
        post :refer
      end
      member do
        get :add
        get :calendar
        get :policies
        post :reserve_slot
        post :filter_slots
        post :cancel_reserve
        post :remove
        get :finish
        get :review
        get :review_duplicates
      end
    end
    resources :orders do
      collection do
        get :policies
        get :appointment_list
        get :office_search
        get :new_office_list
        get :set_delivery
        get :menu
      end
      member do
        get :select_item
        get :remove_item
        get :edit_item
        post :add_item
        post :download
        post :print
        patch :update_item
        get :payment
        patch :save_payment
        post :cancel
        get :confirm
        patch :complete_order
        get :complete
        post :undo_changes
        post :reorder
        post :review
      end
    end
    resources :appointments do
      collection do
        get :prompt_schedule
        get :policies
        get :display_duplicate
        get :schedule
      end
      member do
        get :reorder_meal
        get :select_restaurant
        get :prior_order
        get :select_food
        get :finish
        get :byo
        get :show_sample
        get :show_existing
        get :order_recommendation
        get :finish
        get :book_standby
        get :display_booked    
        post :deliver_samples
        post :filter_restaurants
        post :confirm
        post :sort_restaurants
        post :cancel_confirm
        post :cancel
      end
    end
    resources :restaurants do
      member do
        get :reviews
      end
    end
    resources :calendars do
      collection do
        get :current
        get :filter_appointments
        get :filter_orders
      end
    end
    resources :notifications do
      member do
        post :remove
      end
      collection do
        get :index
        get :dropdown
      end
    end
  end


  # API Fun

  mount GrapeSwaggerRails::Engine => '/api_test'

  namespace :api do

    #unauthed routes to do actions from email
    namespace :email do
      resources :orders do
        collection do
          get :confirm
        end
      end
    end

    namespace :frontend do
      resources :appointments do
        collection do
          get :office_manager
        end
      end
      resources :orders
      resources :companies
      resources :slots do
        collection do
          get :day_of_weeks
        end
      end
      resources :providers do
        collection do
          get :specialties
          get :titles
        end
      end
      resources :restaurants do
        collection do
          get :cuisines
        end
      end
    end

    namespace :v1 do
      resources :auth do
        collection do
          post :login
          post :register
          post :change
          post :password
          get :status
          get :profile
        end
      end

      resources :meta do
        collection do
          post :company # Creation of new companies, standalone
        end
      end

      resources :appointments do
        collection do
          post :create
          post :activate_multiple
          post :cancel
          post :confirm
          put :update
        end
      end
      resources :slots do
      end

      resources :offices do
      end

      resources :orders do
      end

      resources :restaurants do
      end

      resources :providers do
      end

      resources :sales_reps do
      	collection do
      		post :upload_image
      		patch :update_rewards_email
      		get :appointment_date_range
      	end
      end

      resources :notifications do
      end

      resources :offices_sales_reps do
      end

      resources :sales_rep_partners do
      end

      resources :drugs do
      end

      resources :companies do
      end

      resources :menus do
      end

      resources :menu_items do
      end

      resources :order_reviews do
      end

      resources :office_referrals do
      end

      resources :payment_methods do
      		collection do
      			post :set_default
      		end
      end

      resources :office_device_logs do
      end

      resources :user_notification_prefs do
      end
    end

    # * * API Docs
    resources :apidocs, only: [:index]
  end

  # Error Display
  get '*unmatched_route', to: 'exceptions#not_found'
  match "/500", :to => "exceptions#internal_server_error", :via => :all
  match "/400", :to => "exceptions#not_found", :via => :all

end
