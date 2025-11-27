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
    // Use Bootstrap Alert for graceful fade-out when available
    const Alert = window.bootstrap?.Alert;
    if (Alert) {
      const instance =
        Alert.getInstance?.(this.element) || new Alert(this.element);
      instance.close();
      return;
    }

    // Fallback: remove element immediately
    this.element.remove();
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout);
    }
  }
}
