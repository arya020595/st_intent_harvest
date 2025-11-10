import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="toast"
export default class extends Controller {
  static targets = ["container"];

  connect() {
    // Ensure the container exists
    if (!this.hasContainerTarget) {
      console.error("Toast controller requires a container target");
    }
  }

  // Show a toast notification
  // @param message {String} - The message to display
  // @param type {String} - The type of toast (success, error, warning, info)
  // @param duration {Number} - How long to show the toast in milliseconds (default: 5000)
  show(message, type = "info", duration = 5000) {
    const toastId = `toast-${Date.now()}`;
    const toastHtml = this.buildToastHtml(toastId, message, type);

    // Add toast to container
    this.containerTarget.insertAdjacentHTML("beforeend", toastHtml);

    // Get the toast element and initialize Bootstrap Toast
    const toastElement = document.getElementById(toastId);
    const bsToast = new bootstrap.Toast(toastElement, {
      autohide: true,
      delay: duration,
    });

    // Show the toast
    bsToast.show();

    // Remove toast from DOM after it's hidden
    toastElement.addEventListener("hidden.bs.toast", () => {
      toastElement.remove();
    });
  }

  buildToastHtml(id, message, type) {
    const iconMap = {
      success: "bi-check-circle-fill",
      error: "bi-exclamation-circle-fill",
      warning: "bi-exclamation-triangle-fill",
      info: "bi-info-circle-fill",
    };

    const bgColorMap = {
      success: "bg-success",
      error: "bg-danger",
      warning: "bg-warning",
      info: "bg-info",
    };

    const icon = iconMap[type] || iconMap.info;
    const bgColor = bgColorMap[type] || bgColorMap.info;
    const textColor = type === "warning" ? "text-dark" : "text-white";

    return `
      <div id="${id}" class="toast align-items-center ${bgColor} ${textColor} border-0" role="alert" aria-live="assertive" aria-atomic="true">
        <div class="d-flex">
          <div class="toast-body">
            <i class="bi ${icon} me-2"></i>
            ${this.escapeHtml(message)}
          </div>
          <button type="button" class="btn-close btn-close-${type === "warning" ? "dark" : "white"} me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
        </div>
      </div>
    `;
  }

  escapeHtml(text) {
    const div = document.createElement("div");
    div.textContent = text;
    return div.innerHTML;
  }

  // Public methods that can be called from other controllers
  showSuccess(message, duration = 5000) {
    this.show(message, "success", duration);
  }

  showError(message, duration = 5000) {
    this.show(message, "error", duration);
  }

  showWarning(message, duration = 5000) {
    this.show(message, "warning", duration);
  }

  showInfo(message, duration = 5000) {
    this.show(message, "info", duration);
  }
}
