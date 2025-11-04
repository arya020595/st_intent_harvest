import { Controller } from "@hotwired/stimulus";

/**
 * SearchFormController
 *
 * Handles search form submissions to ensure pagination resets to page 1.
 * This prevents issues where searching from page 2+ would show no results.
 *
 * Usage:
 *   <%= search_form_for @q, html: { data: { controller: "search-form", action: "submit->search-form#resetPage" } } do |f| %>
 *     ...
 *   <% end %>
 */
export default class extends Controller {
  /**
   * Reset pagination to page 1 when form is submitted
   * @param {Event} event - Form submit event
   */
  resetPage(event) {
    event.preventDefault();

    const form = event.target;
    const url = new URL(form.action || window.location.href);
    const formData = new FormData(form);

    // Clear existing search params
    url.search = "";

    // Add all form data to URL params
    for (const [key, value] of formData.entries()) {
      if (value) {
        url.searchParams.append(key, value);
      }
    }

    // Ensure page parameter is removed (will default to page 1)
    url.searchParams.delete("page");

    // Navigate to the new URL
    window.location.href = url.toString();
  }
}
