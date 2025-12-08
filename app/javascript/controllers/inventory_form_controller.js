import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["ordersContainer", "orderTemplate", "orderRow"];

  addOrder(event) {
    event.preventDefault();

    const content = this.orderTemplateTarget.innerHTML;
    const newId = new Date().getTime();
    const newContent = content.replace(/NEW_RECORD/g, newId);

    this.ordersContainerTarget.insertAdjacentHTML("beforeend", newContent);
  }

  removeOrder(event) {
    event.preventDefault();

    const row = event.target.closest('[data-inventory-form-target="orderRow"]');
    const destroyField = row.querySelector('input[name*="_destroy"]');

    if (destroyField) {
      // If record exists in database, mark for destruction
      if (row.querySelector('input[type="hidden"][name*="[id]"]')) {
        destroyField.value = "1";
        row.style.display = "none";
      } else {
        // If new record, just remove from DOM
        row.remove();
      }
    } else {
      row.remove();
    }
  }
}
