import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="work-order-rate-form"
export default class extends Controller {
  static targets = ["rateType", "unitField", "rateField"];

  connect() {
    // Initialize visibility on page load
    this.toggleUnitAndRate();
  }

  toggleUnitAndRate() {
    const selectedType = this.rateTypeTarget.value;

    // Hide unit field and rate field when "work_days" or "resource" is selected
    if (selectedType === "work_days" || selectedType === "resource") {
      // Hide and disable unit field
      this.unitFieldTarget.style.display = "none";
      const unitSelect = this.unitFieldTarget.querySelector("select");
      if (unitSelect) {
        unitSelect.removeAttribute("required");
      }

      // Hide rate field (including label) and set value to 0
      this.rateFieldTarget.style.display = "none";
      const rateInput = this.rateFieldTarget.querySelector("input");
      if (rateInput) {
        rateInput.value = "";
        rateInput.removeAttribute("required");
      }
    } else {
      // Show unit field for normal type
      this.unitFieldTarget.style.display = "block";
      const unitSelect = this.unitFieldTarget.querySelector("select");
      if (unitSelect && selectedType !== "") {
        unitSelect.setAttribute("required", "required");
      }

      // Show rate field (including label) and add required attribute
      this.rateFieldTarget.style.display = "block";
      const rateInput = this.rateFieldTarget.querySelector("input");
      if (rateInput && selectedType !== "") {
        rateInput.setAttribute("required", "required");
      }
    }
  }
}
