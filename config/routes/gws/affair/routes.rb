Rails.application.routes.draw do
  Gws::Affair::Initializer

  concern :deletion do
    get :delete, on: :member
    delete :destroy_all, on: :collection, path: ''
  end

  concern :soft_deletion do
    match :soft_delete, on: :member, via: [:get, :post]
    post :soft_delete_all, on: :collection
  end

  concern :workflow do
    post :request_update, on: :member
    post :approve_update, on: :member
    post :remand_update, on: :member
    post :pull_up_update, on: :member
    post :restart_update, on: :member
    post :seen_update, on: :member
    match :request_cancel, on: :member, via: [:get, :post]
  end

  gws "affair" do
    get '/' => redirect { |p, req| "#{req.path}/attendance/time_cards/#{Time.zone.now.strftime('%Y%m')}" }, as: :main

    resources :capitals, concerns: :deletion
    resources :duty_hours, concerns: :deletion

    namespace "overtime" do
      resources :files, path: 'files/:state', concerns: [:deletion, :soft_deletion, :workflow]
      get "/search_approvers" => "search_approvers#index", as: :search_approvers
      match "/wizard/:id/approver_setting" => "wizard#approver_setting", via: [:get, :post], as: :approver_setting
      get "/wizard/:id/reroute" => "wizard#reroute", as: :reroute
      post "/wizard/:id/reroute" => "wizard#do_reroute", as: :do_reroute
      match "/wizard/:id" => "wizard#index", via: [:get, :post], as: :wizard

      resources :results, only: [:edit, :update]

      namespace 'management' do
        get "aggregate" => "aggregate#index"
        get "aggregate_over_threshold" => "aggregate#over_threshold"
      end

      namespace "apis" do
        get "week_in_files/:uid" => "files#week_in", as: :files_week_in
        get "week_out_files/:uid" => "files#week_out", as: :files_week_out
      end
    end

    namespace "leave" do
      resources :files, path: 'files/:state', concerns: [:deletion, :soft_deletion, :workflow]
      get "/search_approvers" => "search_approvers#index", as: :search_approvers
      match "/wizard/:id/approver_setting" => "wizard#approver_setting", via: [:get, :post], as: :approver_setting
      get "/wizard/:id/reroute" => "wizard#reroute", as: :reroute
      post "/wizard/:id/reroute" => "wizard#do_reroute", as: :do_reroute
      match "/wizard/:id" => "wizard#index", via: [:get, :post], as: :wizard

      namespace "apis" do
        get "files/:id" => "files#show", as: :file
      end
    end

    namespace "apis" do
      namespace "overtime" do
        resources :results, only: [:edit, :update]
      end
    end

    namespace "attendance" do
      get '/time_cards/' => redirect { |p, req| "#{req.path}/#{Time.zone.now.strftime('%Y%m')}" }, as: :time_card_main
      resources :time_cards, path: 'time_cards/:year_month', only: %i[index] do
        match :download, on: :collection, via: %i[get post]
        get :print, on: :collection
        post :enter, on: :collection
        post :leave, on: :collection
        post :break_enter, path: 'break_enter:index', on: :collection
        post :break_leave, path: 'break_leave:index', on: :collection
        match :memo, path: ':day/memo', on: :collection, via: %i[get post]
        match :time, path: ':day/:type', on: :collection, via: %i[get post]
      end

      namespace 'management' do
        get '/' => redirect { |p, req| "#{req.path}/time_cards/#{Time.zone.now.strftime('%Y%m')}" }, as: :main
        get '/time_cards/' => redirect { |p, req| "#{req.path}/#{Time.zone.now.strftime('%Y%m')}" }, as: :time_card_main
        resources :time_cards, path: 'time_cards/:year_month', except: %i[new create edit update], concerns: %i[deletion] do
          match :memo, path: ':day/memo', on: :member, via: %i[get post]
          match :time, path: ':day/:type', on: :member, via: %i[get post]
          match :download, on: :collection, via: %i[get post]
          match :lock, on: :collection, via: %i[get post]
          match :unlock, on: :collection, via: %i[get post]
        end
      end

      namespace 'apis' do
        namespace 'management' do
          get 'users' => 'users#index'
        end
      end
    end
  end
end
