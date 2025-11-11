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

  # Default pagination value
  DEFAULT_PER_PAGE = Pagy.options[:limit] || 10
  LIMIT_PARAM = 'per_page'

  private

  # Applies Ransack search without default sort
  #
  # Sets @q instance variable with configured Ransack search object.
  # Multi-sort is handled entirely client-side via JavaScript.
  #
  # @param scope [ActiveRecord::Relation] The base scope to search
  # @return [Ransack::Search] Configured ransack search object
  def apply_ransack_search(scope)
    @q = build_ransack_search(scope)
  end

  # Paginates results using Pagy
  #
  # @param results [ActiveRecord::Relation] Results to paginate
  # @return [Array<Pagy, ActiveRecord::Relation>] Pagy object and paginated results
  def paginate_results(results)
    # Use standard offset-based pagination (pagy method) for Pagy v7+.
    # Provides graceful fallback if the requested page overflows.
    pagy_offset(results, pagy_options)
  rescue Pagy::OverflowError => e
    # Fallback: retry with last available page (without mutating params)
    pagy_offset(results, pagy_options.merge(page: e.pagy.last))
  end

  # Builds Ransack search object from params
  #
  # @param scope [ActiveRecord::Relation] The base scope
  # @return [Ransack::Search] Ransack search object
  def build_ransack_search(scope)
    scope.ransack(params[:q])
  end

  # Gets sanitized per_page parameter with default fallback
  #
  # @return [Integer] Sanitized per_page value
  def sanitized_per_page_param
    per_page = params[LIMIT_PARAM].to_i
    per_page.positive? ? per_page : DEFAULT_PER_PAGE
  end

  # Composed pagy options so pagination config stays in one place.
  # Override or extend here if needed (e.g. switch to :keyset for very large tables).
  def pagy_options
    {
      limit: sanitized_per_page_param,
      limit_key: LIMIT_PARAM
    }
  end

  # Helper delegator for pagination abstraction.
  #
  # Provides an indirection layer for pagination, allowing controllers to switch
  # or extend pagination strategies (e.g., offset, keyset) without modifying callers.
  # Override this method in including controllers or concerns to customize pagination logic.
  #
  # @param results [ActiveRecord::Relation] Results to paginate
  # @param options [Hash] Pagination options
  # @return [Array<Pagy, ActiveRecord::Relation>] Pagy object and paginated results
  def pagy_offset(results, options)
    pagy(results, **options)
  end
end
