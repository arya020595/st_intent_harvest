# frozen_string_literal: true

# RansackMultiSort Concern
#
# Provides reusable methods for controllers using Ransack search with multi-sort.
# Follows Interface Segregation Principle - provides focused, cohesive methods.
#
# Usage:
#   class WorkersController < ApplicationController
#     include RansackMultiSort
#
#     def index
#       apply_ransack_search(policy_scope(Worker))
#       @pagy, @workers = paginate_results(@q.result)
#     end
#   end
module RansackMultiSort
  extend ActiveSupport::Concern

  private

  # Applies Ransack search without default sort
  #
  # Sets @q instance variable with configured Ransack search object.
  # Multi-sort is handled entirely client-side via JavaScript.
  #
  # @param scope [ActiveRecord::Relation] The base scope to search
  # @return [Ransack::Search] Configured ransack search object
  def apply_ransack_search(scope)
    @q = scope.ransack(params[:q])
  end

  # Paginates results using Pagy
  #
  # @param results [ActiveRecord::Relation] Results to paginate
  # @return [Array<Pagy, ActiveRecord::Relation>] Pagy object and paginated results
  def paginate_results(results)
    pagy(results, limit: sanitized_per_page_param)
  rescue StandardError => e
    # Handle pagination overflow - return to last valid page
    # Works with all Pagy versions (OverflowError class name changed across versions)
    raise unless e.class.name.include?('Overflow') && e.respond_to?(:pagy)

    pagy(results, limit: sanitized_per_page_param, page: e.pagy.last)
  end

  # Gets sanitized per_page parameter with default fallback
  #
  # @return [Integer] Sanitized per_page value
  def sanitized_per_page_param
    per_page = params[:per_page].to_i
    per_page.positive? ? per_page : (Pagy.options[:limit] || 10)
  end
end
