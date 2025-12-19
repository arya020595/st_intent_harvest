import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="approval-modal"
export default class extends Controller {
  static targets = [
    "remarksField",
    "submitField",
    "buttonGroup",
    "approvalRemarks",
    "errorMessage",
    "errorText",
    "submitButton",
  ];
  static values = {
    workOrderId: String,
    approveUrl: String,
    amendmentUrl: String,
  };

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
    this.hideError();
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
    // Update submit button label for amendment flow
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.innerHTML =
        '<i class="bi bi-check-circle me-1 text-white"></i> Submit';
    }
  }

  showApprovalFlow() {
    this.hideElement(this.remarksFieldTarget);
    this.showElement(this.submitFieldTarget);
    this.hideElement(this.buttonGroupTarget);
    // Update submit button label for approval flow
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.innerHTML =
        '<i class="bi bi-check-circle me-1 text-white"></i> Submit Approval';
    }
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

    this.sendRequest(this.amendmentUrlValue, {
      work_order_history: { remarks },
    });
  }

  submitApprove() {
    this.sendRequest(this.approveUrlValue);
  }

  getRemarksValue() {
    return this.approvalRemarksTarget.value.trim();
  }

  validateRemarks(remarks) {
    if (!remarks) {
      this.showInlineError("Please provide remarks for the amendment request");
      this.approvalRemarksTarget.classList.add("is-invalid");
      return false;
    }
    this.hideError();
    this.approvalRemarksTarget.classList.remove("is-invalid");
    return true;
  }

  sendRequest(url, body = null) {
    const options = this.buildFetchOptions(body);

    fetch(url, options)
      .then((response) => this.handleResponse(response))
      .catch((error) => this.handleError(error));
  }

  buildFetchOptions(body) {
    const options = {
      method: "PATCH",
      headers: this.getRequestHeaders(),
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
    return (
      document
        .querySelector('meta[name="csrf-token"]')
        ?.getAttribute("content") || ""
    );
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
    // Success handled by redirect, no need for alert
    console.log(message);
  }

  showInlineError(message) {
    if (this.hasErrorMessageTarget && this.hasErrorTextTarget) {
      this.errorTextTarget.textContent = message;
      this.errorMessageTarget.style.display = "block";
    }
  }

  hideError() {
    if (this.hasErrorMessageTarget) {
      this.errorMessageTarget.style.display = "none";
      this.approvalRemarksTarget.classList.remove("is-invalid");
    }
  }

  showError(message) {
    alert(message);
  }
}
