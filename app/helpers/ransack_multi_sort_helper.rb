# frozen_string_literal: true

# RansackMultiSortHelper
#
# Provides view helpers for rendering multi-sort UI components.
#
# Usage:
#   <%= per_page_selector(current: params[:per_page]) %>
module RansackMultiSortHelper
  # Default per-page options for pagination selector
  DEFAULT_PER_PAGE_OPTIONS = [10, 25, 50, 100].freeze
  DEFAULT_PER_PAGE = 10

  # Renders a per-page dropdown that preserves search params
  #
  # @param per_page_options [Array<Integer>] Available per-page options
  # @param current [Integer] Currently selected per-page value
  # @return [String] HTML string
  def per_page_selector(per_page_options: DEFAULT_PER_PAGE_OPTIONS, current: DEFAULT_PER_PAGE, frame_id: pagy_frame_id)
    form_with url: request.path, method: :get, local: true,
              html: { class: 'd-inline', data: { turbo_frame: frame_id } } do |f|
      concat hidden_search_fields
      concat render_per_page_select(f, per_page_options, current)
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

  # ===== Shared Turbo/Pagy helpers =====
  # Returns a stable default Turbo Frame id for the current controller scope
  # e.g., 'workers', 'user-management-roles', 'work-order-details'
  def pagy_frame_id
    controller_path.tr('/', '-')
  end

  # Wraps content into a Turbo Frame with a consistent id for the current controller
  # Usage:
  #   <%= turbo_pagy_frame do %>
  #     ... table + filters + footer ...
  #   <% end %>
  def turbo_pagy_frame(id: pagy_frame_id, &block)
    turbo_frame_tag(id, &block)
  end

  # Backwards-compatible helper: render a Bootstrap-styled nav using the passed @pagy instance
  # Adds data-turbo-frame to links so nav updates only the frame when present.
  # Usage in views (safe output):
  #   <%== pagy_bootstrap_nav(@pagy) %>
  def pagy_bootstrap_nav(pagy, aria_label: nil, frame_id: pagy_frame_id, **options)
    options[:aria_label] ||= aria_label if aria_label
    safe_frame_id = ERB::Util.html_escape(frame_id)
    anchor = %(data-turbo-frame="#{safe_frame_id}")
    pagy.series_nav(:bootstrap, **options.merge(anchor_string: anchor))
  end

  # Convenience: render series_nav with automatic frame targeting
  def pagy_series_nav(pagy, style: :bootstrap, frame_id: pagy_frame_id, **options)
    safe_frame_id = ERB::Util.html_escape(frame_id)
    anchor = %(data-turbo-frame="#{safe_frame_id}")
    pagy.series_nav(style, **options.merge(anchor_string: anchor))
  end
end
