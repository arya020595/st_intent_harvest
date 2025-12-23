# frozen_string_literal: true

# Soft Delete Routes Concern
#
# Add soft delete routes to any resourceful route
#
# Usage in routes.rb:
#   concern :soft_deletable do
#     member do
#       patch :restore
#     end
#     collection do
#       get :trash
#     end
#   end
#
#   resources :users, concerns: :soft_deletable
#
# Or use this initializer to auto-register the concern:
#
Rails.application.config.to_prepare do
  ActionDispatch::Routing::Mapper.class_eval do
    def soft_deletable_routes
      member do
        patch :restore
        put :restore
      end
      collection do
        get :trash
      end
    end
  end
end
