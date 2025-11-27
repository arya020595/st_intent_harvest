import { Controller } from "@hotwired/stimulus";

/**
 * History Controller
 * ==================
 * Manages browser history (URL) updates without page reload
 * Follows SOLID principles:
 * - Single Responsibility: Only handles history/URL management
 * - Open/Closed: Extendable via data attributes
 * - Dependency Inversion: Works with any URL, not tied to specific routes
 *
 * BEST PRACTICE: Use this controller instead of eval() or inline JavaScript
 * - More secure (no eval execution)
 * - More testable
 * - Better separation of concerns
 * - Follows Hotwire/Stimulus conventions
 *
 * Usage in turbo_stream.erb:
 *   <%= turbo_stream.update "url-manager",
 *       partial: "shared/url_updater",
 *       locals: { url: some_index_path } %>
 *
 * Or directly in HTML:
 *   <div data-controller="history"
 *        data-history-url-value="<%= some_path %>"
 *        data-action="turbo:frame-load->history#replace"></div>
 */
export default class extends Controller {
  static values = {
    url: String,
    method: { type: String, default: "replaceState" }, // or "pushState"
  };

  // Ensure execution when the element is inserted by a turbo-stream update
  connect() {
    // Trigger once on connect so we don't depend on value change semantics
    this.update();
  }

  /**
   * Replace current URL in history without reload
   * Best for modal deletions where we want to update URL
   * but stay on the same conceptual page
   */
  replace() {
    if (!this.hasUrlValue) {
      console.warn("History controller: No URL value provided");
      return;
    }

    try {
      window.history.replaceState({}, "", this.urlValue);
    } catch (error) {
      console.error("Failed to replace URL:", error);
    }
  }

  /**
   * Push new URL to history (creates new history entry)
   * Best for navigation where back button should work
   */
  push() {
    if (!this.hasUrlValue) {
      console.warn("History controller: No URL value provided");
      return;
    }

    try {
      window.history.pushState({}, "", this.urlValue);
    } catch (error) {
      console.error("Failed to push URL:", error);
    }
  }

  /**
   * Automatic method selection based on data-history-method-value
   * Called when element is connected or when URL value changes
   */
  urlValueChanged() {
    if (!this.hasUrlValue) return;

    // Auto-execute based on method type
    if (this.methodValue === "pushState") {
      this.push();
    } else {
      this.replace();
    }
  }

  /**
   * Manually trigger update (can be called from other controllers)
   */
  update() {
    this.urlValueChanged();
  }
}
