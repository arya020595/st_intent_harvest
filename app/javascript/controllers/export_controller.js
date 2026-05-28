import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["status"];

  connect() {
    this.modalEl = document.getElementById("exportCsvModal");

    if (this.modalEl) {
      this.modalEl.addEventListener("hidden.bs.modal", () => {
        this.resetUI();
      });
    }
  }

  submit(event) {
    // show loading alert
    if (this.hasStatusTarget) {
      this.statusTarget.classList.remove("d-none");
    }

    // disable submit button
    const btn = this.element.querySelector(
      "input[type=submit], button[type=submit]",
    );
    if (btn) btn.disabled = true;

    // close modal after short delay (so user sees status)
    setTimeout(() => {
      const modalEl = document.getElementById("exportCsvModal");
      const modal = bootstrap.Modal.getInstance(modalEl);

      if (modal) modal.hide();
    }, 2000); // 👈 2 seconds
  }

  resetUI() {
    // 1. hide alert
    if (this.hasStatusTarget) {
      this.statusTarget.classList.add("d-none");
    }

    // 2. re-enable submit button
    const btn = this.element.querySelector(
      "input[type=submit], button[type=submit]",
    );
    if (btn) btn.disabled = false;

    // 3. reset checkboxes to default (true)
    this.element
      .querySelectorAll("input[type=checkbox][name='worker_filters[]']")
      .forEach((cb) => (cb.checked = true));
  }
}
