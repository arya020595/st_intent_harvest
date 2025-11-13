import { Controller } from "@hotwired/stimulus";

// Shared/Generic Modal Controller
// Usage: data-controller="modal"
// Works with any Turbo Frame - just specify the frame ID via data-modal-frame-id-value
// Best practice: keep modal container persistent in DOM; load content via <turbo-frame>
export default class extends Controller {
  static values = {
    frameId: { type: String, default: "modal" },
    focusSelector: {
      type: String,
      default: "input:not([type=hidden]), select, textarea",
    },
  };

  connect() {
    // Prefer Bootstrap UMD global when using importmap pin to bootstrap.min.js
    this.BootstrapModal = (window.bootstrap && window.bootstrap.Modal) || null;

    if (!this.BootstrapModal) {
      // As a fallback, try to resolve from ESM import if environment provides it
      // (We avoid direct import to keep compatibility with UMD build.)
      console.warn(
        "Bootstrap Modal not found on window.bootstrap. Ensure 'import \"bootstrap\"' is present in application.js and importmap pins bootstrap.min.js"
      );
    }
    // Bind handlers once so we can remove them later
    this._clearHandler = this.clearFrame.bind(this);
    this._submitHandler = this.formSubmitted.bind(this);

    // Create Bootstrap Modal instance
    if (this.BootstrapModal) {
      this.modal = new this.BootstrapModal(this.element, {
        backdrop: "static",
        keyboard: false,
      });
    }

    // Hide/clear behaviors
    this.element.addEventListener("hidden.bs.modal", this._clearHandler);
    // Close on successful submit (201/200)
    this.element.addEventListener("turbo:submit-end", this._submitHandler);
    // Ensure modal is hidden before caching the page (back/forward nav)
    this.element.addEventListener("turbo:before-cache", () => {
      if (this.modal) this.modal.hide();
    });

    // Focus first input when shown
    this.element.addEventListener("shown.bs.modal", () =>
      this.focusFirstField()
    );
  }

  show() {
    // In rare cases the action may fire before connect created the instance
    if (!this.modal && this.BootstrapModal) {
      this.modal = new this.BootstrapModal(this.element, {
        backdrop: "static",
        keyboard: false,
      });
    }
    if (this.modal) this.modal.show();
  }

  formSubmitted(event) {
    const { success } = event.detail;
    // If validation failed (422), keep modal open to show errors
    if (success) {
      this.modal.hide();
    }
  }

  clearFrame() {
    const frame = this.element.querySelector(
      `turbo-frame#${this.frameIdValue}`
    );
    if (frame) frame.innerHTML = "";
  }

  focusFirstField() {
    const frame = this.element.querySelector(
      `turbo-frame#${this.frameIdValue}`
    );
    if (!frame) return;
    const el = frame.querySelector(this.focusSelectorValue);
    if (el && typeof el.focus === "function") el.focus();
  }

  disconnect() {
    this.element.removeEventListener("hidden.bs.modal", this._clearHandler);
    this.element.removeEventListener("turbo:submit-end", this._submitHandler);

    if (this.modal) this.modal.dispose();
  }
}
