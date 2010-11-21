Pfc::Application.routes.draw do
  ## Dashboard

  root :to => 'dashboard#index'
  get 'dashboard' => redirect('/'), :as => 'dashboard'

  ## Login & Signup

  get  'login'  => 'sessions#new',     :as => 'login'
  post 'login'  => 'sessions#create'
  get  'logout' => 'sessions#destroy', :as => 'logout'

  resource :session

  get  'signup' => 'users#new', :as => 'signup'
  post 'signup' => 'users#create'

  ## Accounts, Transactions, Analytics, & Uploads

  resources :accounts do
    resources :transactions, :controller => 'txactions' do
      member do
        put :undelete
      end
    end

    collection do
      post :enable
      post :trigger_updates
    end

    member do
      get :financial_institution_site
    end
  end

  # TODO: Fix this hack.
  get '/transactions/rational(.:format)' => 'rational_txactions#index'
  get '/transactions/rational/*tags(.:format)', :to => 'rational_txactions#index'

  resources :transactions, :controller => 'txactions' do
    member do
      put :undelete
      get :on_select_merchant
      get :transfer_selector
      get :merchant_list_checks
    end
  end

  resources :tags
  resources :attachments
  resources :account_merchant_tag_stats
  resources :targets
  resources :trends
  resources :uploads do
    collection do
      match :choose
      get   :manual
    end
  end

  # TODO: use resource routing for this
  post '/targets/delete' => 'targets#destroy'

  resources :merchants do
    collection do
      get :my,     :to => 'merchants#user_index'
      get :public, :to => 'merchants#public_index'
    end
  end

  resources :financial_insts, :path => 'financial-institutions'

  ## Member Data Snapshots

  resource  :snapshot

  ## Big Rock Candy Mountain Passthrough

  match '/data/transactions/*uri(.:format)',            :to => 'brcm#transactions'
  match '/data/investment-transactions/*uri(.:format)', :to => 'brcm#transactions'
  match '/data/*uri(.:format)',                         :to => 'brcm#passthrough'

  ## User Profile & Preferences

  resource :profile
  resource :preferences, :controller => 'user_preferences'
  resource :user do
    post :edit_filter_tags, :to => 'users#edit_filter_tags'
    get :password, :to => 'users#edit_password'
    put :password, :to => 'users#update_password'
    get :download_data
    get :delete_membership
  end

  ## Server-Side Uploader

  resources :credentials, :controller => 'account_creds' do
    resources :jobs, :controller => 'ssu_jobs'
  end

  ## Help & About

  get 'page/contribute', :as => :contribute, :to => 'page#contribute'
  get 'page/what',       :as => :what,       :to => 'page#what'
end
