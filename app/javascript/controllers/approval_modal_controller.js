import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="approval-modal"
export default class extends Controller {
  static targets = [
    "remarksField",
    "submitField",
    "buttonGroup",
    "approvalRemarks",
  ];
  static values = { workOrderId: String };

  // Action types constants
  static ACTION_TYPES = {
    AMENDMENT: "amendment",
    APPROVE: "approve",
  };

  connect() {
    this.actionType = null;
    this.setupModalReset();
  }

  setupModalReset() {
    this.element.addEventListener("hidden.bs.modal", () => this.reset());
  }

  reset() {
    this.actionType = null;
    this.hideElement(this.remarksFieldTarget);
    this.hideElement(this.submitFieldTarget);
    this.showElement(this.buttonGroupTarget);
    this.approvalRemarksTarget.value = "";
  }

  selectAmendment(event) {
    this.preventDefault(event);
    this.actionType = this.constructor.ACTION_TYPES.AMENDMENT;
    this.showRemarksFlow();
  }

  selectApprove(event) {
    this.preventDefault(event);
    this.actionType = this.constructor.ACTION_TYPES.APPROVE;
    this.showApprovalFlow();
  }

  submitApproval(event) {
    this.preventDefault(event);

    if (this.actionType === this.constructor.ACTION_TYPES.AMENDMENT) {
      this.submitAmendment();
    } else if (this.actionType === this.constructor.ACTION_TYPES.APPROVE) {
      this.submitApprove();
    }
  }

  // Private methods

  preventDefault(event) {
    event.preventDefault();
    event.stopPropagation();
  }

  showRemarksFlow() {
    this.showElement(this.remarksFieldTarget);
    this.showElement(this.submitFieldTarget);
    this.hideElement(this.buttonGroupTarget);
  }

  showApprovalFlow() {
    this.hideElement(this.remarksFieldTarget);
    this.showElement(this.submitFieldTarget);
    this.hideElement(this.buttonGroupTarget);
  }

  showElement(element) {
    element.style.display =
      element === this.buttonGroupTarget ? "flex" : "block";
  }

  hideElement(element) {
    element.style.display = "none";
  }

  submitAmendment() {
    const remarks = this.getRemarksValue();

    if (!this.validateRemarks(remarks)) {
      return;
    }

    this.sendRequest("/request_amendment", {
      work_order_history: { remarks },
    });
  }

  submitApprove() {
    this.sendRequest("/approve");
  }

  getRemarksValue() {
    return this.approvalRemarksTarget.value.trim();
  }

  validateRemarks(remarks) {
    if (!remarks) {
      this.showError("Please provide remarks for the amendment request");
      return false;
    }
    return true;
  }

  sendRequest(endpoint, body = null) {
    const url = `/work_order/approvals/${this.workOrderIdValue}${endpoint}`;
    const options = this.buildFetchOptions(body);

    fetch(url, options)
      .then((response) => this.handleResponse(response))
      .catch((error) => this.handleError(error));
  }

  buildFetchOptions(body) {
    const options = {
      method: "PATCH",
      headers: this.getRequestHeaders(),
      redirect: "manual", // Changed from "follow" to prevent auto-redirect
    };

    if (body) {
      options.body = JSON.stringify(body);
    }

    return options;
  }

  getRequestHeaders() {
    return {
      "Content-Type": "application/json",
      Accept: "application/json", // Request JSON response
      "X-CSRF-Token": this.getCsrfToken(),
    };
  }

  getCsrfToken() {
    return document
      .querySelector('meta[name="csrf-token"]')
      .getAttribute("content");
  }

  async handleResponse(response) {
    if (response.ok) {
      const data = await response.json();

      if (data.success && data.redirect_url) {
        // Show success message if available
        if (data.message) {
          this.showSuccess(data.message);
        }
        // Redirect to the URL provided by the server
        window.location.href = data.redirect_url;
      } else {
        window.location.reload();
      }
    } else {
      // Handle error response
      try {
        const data = await response.json();
        this.showError(data.error || "An error occurred. Please try again.");
      } catch {
        this.showError("An error occurred. Please try again.");
      }
    }
  }

  handleError(error) {
    console.error("Request failed:", error);
    this.showError("An error occurred. Please try again.");
  }

  showSuccess(message) {
    // You can replace this with a better notification system (e.g., toast)
    alert(message);
  }

  showError(message) {
    alert(message);
  }
}
