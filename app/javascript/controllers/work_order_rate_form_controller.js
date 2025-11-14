import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="work-order-rate-form"
export default class extends Controller {
  static targets = ["rateType", "unitField"];

  connect() {
    // Initialize visibility on page load
    this.toggleUnit();
  }

  toggleUnit() {
    const selectedType = this.rateTypeTarget.value;

    // Hide unit field when "work_days" is selected
    if (selectedType === "work_days") {
      this.unitFieldTarget.style.display = "none";
      // Remove required attribute when hidden
      const unitSelect = this.unitFieldTarget.querySelector("select");
      if (unitSelect) {
        unitSelect.removeAttribute("required");
      }
    } else {
      this.unitFieldTarget.style.display = "block";
      // Add required attribute when visible (for normal and resources)
      const unitSelect = this.unitFieldTarget.querySelector("select");
      if (unitSelect && selectedType !== "") {
        unitSelect.setAttribute("required", "required");
      }
    }
  }
}
