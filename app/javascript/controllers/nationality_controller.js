// app/javascript/controllers/nationality_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["identityField"];

  connect() {
    this.toggleIdentity(); // Run on page load to hide if needed
  }

  toggleIdentity() {
    const selected = this.element.querySelector("select").value;
    // Check for normalized database value
    if (selected === "foreigner_no_passport") {
      this.identityFieldTarget.style.display = "none";
      this.identityFieldTarget.querySelector("input").value = ""; // optional: clear value
    } else {
      this.identityFieldTarget.style.display = "";
    }
  }
}
