# frozen_string_literal: true

# RansackMultiSortHelper
#
# Provides view helpers for rendering multi-sort UI components and pagination.
#
# SECURITY NOTE:
# This helper properly whitelists Ransack query parameters to prevent
# unintended mass assignment of unexpected parameters. Use these helpers
# instead of calling .to_unsafe_h directly on params[:q].
#
# Usage:
#   <%= per_page_selector(current: params[:per_page]) %>
#   <%== pagy_bootstrap_nav(@pagy) %>
#   <% safe_params = sanitized_ransack_params %>
module RansackMultiSortHelper
  # Default per-page options for pagination selector
  DEFAULT_PER_PAGE_OPTIONS = [10, 25, 50, 100].freeze

  # Whitelisted Ransack search parameters for Productions
  # Only these parameters are allowed to prevent mass assignment of unexpected attributes
  ALLOWED_PRODUCTION_SEARCH_KEYS = {
    date_gteq: :string,
    date_lteq: :string,
    block_id_eq: :string,
    mill_id_eq: :string,
    s: :string  # Sort parameter
  }.freeze

  # ===== Per-page selector =====

  # Renders a per-page dropdown that preserves search params
  #
  # @param per_page_options [Array<Integer>] Available per-page options
  # @param current [Integer] Currently selected per-page value
  # @return [String] HTML string
  def per_page_selector(per_page_options: DEFAULT_PER_PAGE_OPTIONS, current: nil)
    current ||= Pagy.options[:limit]
    form_with url: request.path, method: :get, local: true,
              html: { class: 'd-inline' } do |f|
      concat hidden_search_fields
      concat render_per_page_select(f, per_page_options, current)
    end
  end

  # ===== (Removed) Turbo Frame helpers =====
  # Note: We are not using Turbo Frames for pagination anymore, so the
  # previous pagy_frame_id and turbo_pagy_frame helpers have been removed.

  # ===== Pagination navigation helpers =====

  # Renders Bootstrap-styled pagination nav (Pagy 43 object helper)
  # Usage in views (safe output):
  #   <%== pagy_bootstrap_nav(@pagy) %>
  #   <%== pagy_bootstrap_nav(@pagy, aria_label: 'Product pages') %>
  #
  # @param pagy [Pagy] Pagy instance
  # @param aria_label [String] Optional ARIA label for accessibility
  # @param options [Hash] Additional options passed to series_nav
  # @return [String] HTML string
  def pagy_bootstrap_nav(pagy, aria_label: nil, **options)
    return '' unless pagy # Guard against nil @pagy

    options[:aria_label] ||= aria_label if aria_label

    # Pagy 43 provides the @pagy object helpers; use series_nav with :bootstrap style
    pagy.series_nav(:bootstrap, **options)
  end

  private

  # Renders per-page select element
  #
  # @param form [ActionView::Helpers::FormBuilder] Form builder
  # @param options [Array<Integer>] Per-page options
  # @param current [Integer] Current value
  # @return [String] HTML string
  def render_per_page_select(form, options, current)
    form.select(:per_page,
                options_for_select(options, current),
                {},
                { class: 'form-select form-select-sm d-inline-block',
                  style: 'width: auto;',
                  onchange: 'this.form.submit()' })
  end

  # Generates hidden fields for all search params except sorts
  #
  # Uses sanitized_ransack_params to only pass whitelisted parameters
  #
  # @return [String] HTML safe string with hidden fields
  def hidden_search_fields
    return '' unless params[:q]

    sanitized_ransack_params.map do |key, value|
      hidden_field_tag "q[#{key}]", value
    end.compact.join.html_safe
  end

  # Sanitizes Ransack query parameters using a whitelist
  #
  # Only allows explicitly whitelisted search parameters to prevent
  # mass assignment of unexpected parameters. This is more secure than
  # using .to_unsafe_h which accepts any parameter without validation.
  #
  # @param allowed_keys [Hash] Hash of allowed parameter keys and types
  # @return [Hash] Filtered hash containing only whitelisted parameters
  #
  # @example
  #   safe_params = sanitized_ransack_params(ALLOWED_PRODUCTION_SEARCH_KEYS)
  #   # => { date_gteq: "2024-01-01", date_lteq: "2024-12-31" }
  def sanitized_ransack_params(allowed_keys = ALLOWED_PRODUCTION_SEARCH_KEYS)
    return {} unless params[:q].present?

    safe_params = {}
    params[:q].to_unsafe_h.each do |key, value|
      key_sym = key.to_sym
      if allowed_keys.key?(key_sym)
        safe_params[key_sym] = value
      else
        Rails.logger.warn("[Security] Skipped disallowed Ransack parameter: #{key}")
      end
    end

    safe_params
  end

  # Helper for export URLs - includes only whitelisted parameters
  #
  # Safely passes Ransack parameters to export endpoints without
  # allowing unintended mass assignment of unexpected parameters.
  #
  # @return [Hash] Filtered query parameters safe for export URLs
  #
  # @example
  #   export_params[:q] = safe_export_params
  def safe_export_params
    sanitized_ransack_params
  end

  private

  # Generates array of hidden field tags using sanitized params
  #
  # @deprecated Use hidden_search_fields instead (now internally uses sanitized params)
  # @return [Array<String>] Array of hidden field HTML strings
  def generate_hidden_fields
    sanitized_ransack_params.map do |key, value|
      hidden_field_tag "q[#{key}]", value
    end
  end
end
