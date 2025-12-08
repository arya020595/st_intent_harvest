import { Controller } from "@hotwired/stimulus";

/**
 * SearchFormController
 *
 * Handles:
 *  - autoSubmit: Debounced form submit (use for text fields)
 *  - instantSubmit: Immediate form submit (use for dropdowns or checkboxes)
 *  - resetPage: Rebuilds URL and removes pagination before navigating
 */
export default class extends Controller {
  /**
   * Debounced auto-submit (e.g. for text inputs)
   */
  autoSubmit(event) {
    clearTimeout(this.timeout);

    this.timeout = setTimeout(() => {
      this.element.requestSubmit();
    }, 300); // adjust debounce time as needed
  }

  /**
   * Immediate submit (no debounce)
   */
  instantSubmit(event) {
    this.element.requestSubmit();
  }

  /**
   * Reset pagination and rebuild URL on form submission
   */
  resetPage(event) {
    event.preventDefault();

    const form = event.target;
    const url = new URL(form.action || window.location.href);
    const formData = new FormData(form);

    // Clear any existing params
    url.search = "";

    // Add submitted form parameters
    for (const [key, value] of formData.entries()) {
      if (value !== "") {
        url.searchParams.append(key, value);
      }
    }

    // Always reset to page 1
    url.searchParams.delete("page");

    // Redirect
    window.location.href = url.toString();
  }
}
