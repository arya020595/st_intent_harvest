# frozen_string_literal: true

# RansackMultiSortHelper
#
# Provides view helpers for rendering multi-sort UI components and pagination.
#
# Usage:
#   <%= per_page_selector(current: params[:per_page]) %>
#   <%== pagy_bootstrap_nav(@pagy) %>
module RansackMultiSortHelper
  # Default per-page options for pagination selector
  DEFAULT_PER_PAGE_OPTIONS = [10, 25, 50, 100].freeze

  # ===== Per-page selector =====

  # Renders a per-page dropdown that preserves search params
  #
  # @param per_page_options [Array<Integer>] Available per-page options
  # @param current [Integer] Currently selected per-page value
  # @param frame_id [String] Turbo frame ID for scoped updates
  # @return [String] HTML string
  def per_page_selector(per_page_options: DEFAULT_PER_PAGE_OPTIONS, current: nil, frame_id: pagy_frame_id)
    current ||= Pagy.options[:limit]
    form_with url: request.path, method: :get, local: true,
              html: { class: 'd-inline', data: { turbo_frame: frame_id } } do |f|
      concat hidden_search_fields
      concat render_per_page_select(f, per_page_options, current)
    end
  end

  # ===== Turbo Frame helpers =====

  # Returns a stable default Turbo Frame id for the current controller scope
  # e.g., 'workers', 'user-management-roles', 'work-order-details'
  #
  # @return [String] Frame ID derived from controller path
  def pagy_frame_id
    controller_path.tr('/', '-')
  end

  # Wraps content into a Turbo Frame with a consistent id for the current controller
  # Usage:
  #   <%= turbo_pagy_frame do %>
  #     ... table + filters + footer ...
  #   <% end %>
  #
  # @param id [String] Custom frame ID (defaults to pagy_frame_id)
  # @yield Block content to wrap in the frame
  # @return [String] HTML string
  def turbo_pagy_frame(id: pagy_frame_id, &block)
    turbo_frame_tag(id, &block)
  end

  # ===== Pagination navigation helpers =====

  # Renders Bootstrap-styled pagination nav with Turbo Frame support
  # Adds data-turbo-frame to links so nav updates only the frame when present.
  # Usage in views (safe output):
  #   <%== pagy_bootstrap_nav(@pagy) %>
  #   <%== pagy_bootstrap_nav(@pagy, aria_label: 'Product pages') %>
  #
  # @param pagy [Pagy] Pagy instance
  # @param aria_label [String] Optional ARIA label for accessibility
  # @param frame_id [String] Turbo frame ID for link targeting
  # @param options [Hash] Additional options passed to series_nav
  # @return [String] HTML string
  def pagy_bootstrap_nav(pagy, aria_label: nil, frame_id: pagy_frame_id, **options)
    return '' unless pagy # Guard against nil @pagy

    options[:aria_label] ||= aria_label if aria_label
    safe_frame_id = ERB::Util.html_escape(frame_id)
    anchor = %(data-turbo-frame="#{safe_frame_id}")

    # Use the modern Pagy object helper (series_nav) instead of the removed extra
    if pagy.respond_to?(:series_nav)
      pagy.series_nav(:bootstrap, **options.merge(anchor_string: anchor))
    else
      # Fallback: generate basic nav if series_nav is not available
      pagy_nav(pagy, **options.merge(anchor_string: anchor))
    end
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
  # @return [String] HTML safe string with hidden fields
  def hidden_search_fields
    return '' unless params[:q]

    generate_hidden_fields.compact.join.html_safe
  end

  # Generates array of hidden field tags
  #
  # @return [Array<String>] Array of hidden field HTML strings
  def generate_hidden_fields
    params[:q].to_unsafe_h.map do |key, value|
      next if key.to_s == 's' # Skip sort parameters

      hidden_field_tag "q[#{key}]", value
    end
  end
end
