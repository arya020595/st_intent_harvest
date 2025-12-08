import { Controller } from "@hotwired/stimulus";

/**
 * SearchFormController
 *
 * Handles:
 *  - Auto-submit when user types in filters (debounced)
 *  - Resetting pagination to page 1 on submit
 */
export default class extends Controller {
  /**
   * Auto-submit the form when user types in a field.
   * Debounced to avoid excessive calls.
   */
  autoSubmit(event) {
    clearTimeout(this.timeout);

    this.timeout = setTimeout(() => {
      this.element.requestSubmit();
    }, 300); // adjust debounce delay if needed
  }
  /**
   * Reset pagination to page 1 when form is submitted
   */
  resetPage(event) {
    event.preventDefault();

    const form = event.target;
    const url = new URL(form.action || window.location.href);
    const formData = new FormData(form);

    // Clear existing search params
    url.search = "";

    // Apply new search params
    for (const [key, value] of formData.entries()) {
      if (value !== "") {
        url.searchParams.append(key, value);
      }
    }

    // Remove pagination parameter (forces page 1)
    url.searchParams.delete("page");

    // Redirect
    window.location.href = url.toString();
  }
}
