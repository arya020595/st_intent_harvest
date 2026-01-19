import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "selectedContainer",
    "selectAll",
    "workerCheckbox",
    "searchInput",
    "workerItem",
    "monthSelect",
    "yearSelect",
    "generateBtn",
  ];

  connect() {
    this.syncFromCheckboxes();
    this.updateGenerateButtonState();
  }

  addWorker(id, name) {
    if (document.getElementById(`selected-worker-${id}`)) return;

    const chip = document.createElement("span");
    chip.className = "worker-chip d-flex align-items-center";
    chip.id = `selected-worker-${id}`;

    // Create text node to safely display worker name (prevents XSS)
    const nameText = document.createTextNode(name);
    chip.appendChild(nameText);

    // Add a space before the button
    chip.appendChild(document.createTextNode(" "));

    // Create remove button
    const button = document.createElement("button");
    button.type = "button";
    button.className = "remove-worker";
    button.dataset.workerId = id;
    button.dataset.action = "click->payslip-filter#removeWorkerClick";

    // Safely construct aria-label text to avoid introducing HTML/XSS
    const ariaLabelSpan = document.createElement("span");
    ariaLabelSpan.textContent = `Remove ${name}`;
    button.setAttribute("aria-label", ariaLabelSpan.textContent);
    button.innerHTML = '<i class="bi bi-x-circle-fill"></i>';

    chip.appendChild(button);
    this.selectedContainerTarget.appendChild(chip);
  }

  removeWorker(id) {
    document.getElementById(`selected-worker-${id}`)?.remove();
    const checkbox = document.getElementById(`worker_${id}`);
    if (checkbox) checkbox.checked = false;

    if (
      this.hasSelectAllTarget &&
      !this.workerCheckboxTargets.every((c) => c.checked)
    ) {
      this.selectAllTarget.checked = false;
    }

    this.updateGenerateButtonState();
  }

  removeWorkerClick(event) {
    const removeButton = event.target.closest(".remove-worker");
    if (!removeButton) return;
    this.removeWorker(removeButton.dataset.workerId);
  }

  syncFromCheckboxes() {
    this.selectedContainerTarget.innerHTML = "";
    this.workerCheckboxTargets.forEach((cb) => {
      if (cb.checked) this.addWorker(cb.value, cb.dataset.workerName);
    });
  }

  toggleWorkerCheckbox(event) {
    const checkbox = event.currentTarget;

    if (checkbox.checked) {
      this.addWorker(checkbox.value, checkbox.dataset.workerName);
    } else {
      this.removeWorker(checkbox.value);
    }

    if (!checkbox.checked) {
      if (this.hasSelectAllTarget) this.selectAllTarget.checked = false;
    } else if (this.workerCheckboxTargets.every((c) => c.checked)) {
      if (this.hasSelectAllTarget) this.selectAllTarget.checked = true;
    }

    this.updateGenerateButtonState();
  }

  toggleSelectAll(event) {
    const isChecked = event.currentTarget.checked;

    if (isChecked) {
      // Check all checkboxes
      this.workerCheckboxTargets.forEach((cb) => {
        cb.checked = true;
      });

      // Clear container and build worker chips safely
      this.selectedContainerTarget.innerHTML = "";
      this.workerCheckboxTargets.forEach((cb) => {
        const id = cb.value;
        const name = cb.dataset.workerName;
        this.addWorker(id, name);
      });
    } else {
      // Uncheck all checkboxes and clear all selected worker chips
      this.workerCheckboxTargets.forEach((cb) => {
        cb.checked = false;
      });
      this.selectedContainerTarget.innerHTML = "";
    }
    this.updateGenerateButtonState();
  }

  searchWorkers(event) {
    const query = event.currentTarget.value.toLowerCase().trim();

    this.workerItemTargets.forEach((item) => {
      const name = item.dataset.workerName;
      item.style.display = name.includes(query) ? "" : "none";
    });
  }

  updateGenerateButtonState() {
    if (
      !this.hasMonthSelectTarget ||
      !this.hasYearSelectTarget ||
      !this.hasGenerateBtnTarget
    )
      return;

    const monthSelected = this.monthSelectTarget.value !== "";
    const yearSelected = this.yearSelectTarget.value !== "";
    const workerSelected = this.workerCheckboxTargets.some((cb) => cb.checked);

    this.generateBtnTarget.disabled = !(
      monthSelected &&
      yearSelected &&
      workerSelected
    );
  }

  filterChange() {
    this.updateGenerateButtonState();
  }
}
