# frozen_string_literal: true

Rails.application.routes.draw do
  # Soft delete restore route concern
  concern :restorable do
    member do
      patch :restore
    end
  end

  devise_for :users,
             controllers: {
               sessions: 'users/sessions',
               registrations: 'users/registrations',
               passwords: 'users/passwords',
               confirmations: 'users/confirmations',
               unlocks: 'users/unlocks'
             }

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Defines the root path route ("/")
  root 'dashboard#index'

  # Dashboard
  get 'dashboard', to: 'dashboard#index'
  # BI Dashboard
  get 'bi_dashboard', to: 'bi_dashboard#index', as: :bi_dashboard

  # Work Order Namespace
  namespace :work_orders do
    resources :details, concerns: :restorable do
      member do
        patch :mark_complete
        get :confirm_delete
      end
    end
    resources :approvals, only: %i[index show update] do
      member do
        patch :approve
        patch :request_amendment
      end
    end
    resources :pay_calculations do
      member do
        get :worker_detail
      end
    end
    resources :mandays, concerns: :restorable
  end

  # Payslips
  resources :payslips, only: %i[index show] do
    collection do
      get :export
    end
  end

  # Inventory
  resources :inventories, concerns: :restorable do
    member do
      get :confirm_delete
    end
    resources :inventory_orders, concerns: :restorable do
      member do
        get :confirm_delete
      end
    end
  end

  # Workers
  resources :workers, concerns: :restorable do
    member do
      get :confirm_delete
    end
  end

  # Master Data Namespace
  namespace :master_data do
    resources :vehicles, concerns: :restorable do
      member do
        get :confirm_delete
      end
    end

    resources :work_order_rates, concerns: :restorable do
      member do
        get :confirm_delete
      end
    end

    resources :blocks, concerns: :restorable do
      member do
        get :confirm_delete
      end
    end

    resources :units, concerns: :restorable do
      member do
        get :confirm_delete
      end
    end

    resources :categories, concerns: :restorable do
      member do
        get :confirm_delete
      end
    end
  end

  # User Management Namespace
  namespace :user_management do
    resources :roles, concerns: :restorable do
      member do
        get :confirm_delete
      end
    end

    resources :users, concerns: :restorable do
      member do
        get :confirm_delete
      end
    end
  end
end
