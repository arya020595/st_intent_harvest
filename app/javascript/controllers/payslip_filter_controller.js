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
    "pageResetBtn", // bottom reset link
  ];

  connect() {
    // Clear search input on load
    if (this.hasSearchInputTarget) {
      this.searchInputTarget.value = "";
    }

    // Show all workers first
    this.workerItemTargets.forEach((item) => {
      item.style.display = "";
    });

    this.syncFromCheckboxes();
    this.updateGenerateButtonState();
    this.updateResetButtonVisibility();
  }

  // Add a worker chip
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

  // Remove a worker chip
  removeWorker(id) {
    const chip = document.getElementById(`selected-worker-${id}`);
    if (chip) chip.remove();

    const checkbox = document.getElementById(`worker_${id}`);
    if (checkbox) checkbox.checked = false;

    // Update Select All if needed
    if (
      this.hasSelectAllTarget &&
      !this.workerCheckboxTargets.every((cb) => cb.checked)
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

  // Sync chips from checkboxes
  syncFromCheckboxes() {
    // Clear chips
    this.selectedContainerTarget.innerHTML = "";

    this.workerCheckboxTargets.forEach((cb) => {
      if (cb.checked) this.addWorker(cb.value, cb.dataset.workerName);

      // IMPORTANT: make all worker items visible again
      cb.closest(".worker-item").style.display = "";
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
    } else if (this.workerCheckboxTargets.every((cb) => cb.checked)) {
      if (this.hasSelectAllTarget) this.selectAllTarget.checked = true;
    }

    this.updateGenerateButtonState();
    this.updateResetButtonVisibility();
  }

  toggleSelectAll(event) {
    const isChecked = event.currentTarget.checked;

    this.workerCheckboxTargets.forEach((cb) => {
      cb.checked = isChecked;

      if (isChecked) this.addWorker(cb.value, cb.dataset.workerName);
      else this.removeWorker(cb.value);

      // Always make the item visible
      cb.closest(".worker-item").style.display = "";
    });

    this.updateGenerateButtonState();
    this.updateResetButtonVisibility();
  }

  searchWorkers(event) {
    const query = event.currentTarget.value.toLowerCase().trim();

    this.workerItemTargets.forEach((item) => {
      const name = item.dataset.workerName;
      const checkbox = item.querySelector(".worker-checkbox");

      // Always show checked workers
      if (checkbox.checked) {
        item.style.display = "";
        return;
      }

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

  updateResetButtonVisibility() {
    const monthFilled =
      this.hasMonthSelectTarget && this.monthSelectTarget.value !== "";
    const yearFilled =
      this.hasYearSelectTarget && this.yearSelectTarget.value !== "";
    const workersSelected = this.workerCheckboxTargets.some((cb) => cb.checked);

    const shouldShow = monthFilled || yearFilled || workersSelected;

    // Dropdown reset
    if (this.hasResetBtnTarget) {
      this.resetBtnTarget.style.display = shouldShow ? "inline-block" : "none";
    }

    // Bottom page reset
    if (this.hasPageResetBtnTarget) {
      this.pageResetBtnTarget.style.display = shouldShow
        ? "inline-block"
        : "none";
    }
  }

  filterChange() {
    this.updateGenerateButtonState();
    this.updateResetButtonVisibility();
  }
}
