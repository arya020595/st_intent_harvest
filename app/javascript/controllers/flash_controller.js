import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="flash"
// Auto-dismisses flash messages after a specified delay
export default class extends Controller {
  static values = {
    delay: { type: Number, default: 5000 },
  };

  connect() {
    // Auto-dismiss after delay
    this.timeout = setTimeout(() => {
      this.dismiss();
    }, this.delayValue);
  }

  dismiss() {
    // Find Bootstrap Alert instance if available, otherwise just remove element
    const bsAlert = window.bootstrap?.Alert?.getInstance(this.element);
    if (bsAlert) {
      bsAlert.close();
    } else {
      this.element.remove();
    }
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout);
    }
  }
}
