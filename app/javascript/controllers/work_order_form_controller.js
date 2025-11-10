import { Controller } from "@hotwired/stimulus";

/**
 * WorkOrderFormController
 *
 * Handles dynamic form interactions for work order creation/editing:
 * - Auto-fill work order rate and unit when work order is selected
 * - Add/remove resource rows dynamically
 * - Auto-fill resource details when inventory is selected
 * - Add/remove worker rows dynamically
 * - Auto-fill worker rate and calculate amount
 */
export default class extends Controller {
  static targets = ["resourcesContainer", "workersContainer"];
  static values = {
    inventories: Array,
    workers: Array,
    resourceIndexStart: Number,
    workerIndexStart: Number,
  };

  connect() {
    console.log("WorkOrderFormController connected");
    // Start indexes after any pre-rendered rows from the server
    const existingResourceRows = this.resourcesContainerTarget.querySelectorAll(
      "tr[data-resource-index]"
    ).length;
    const existingWorkerRows = this.workersContainerTarget.querySelectorAll(
      "tr[data-worker-index]"
    ).length;

    this.resourceIndex = Number.isInteger(this.resourceIndexStartValue)
      ? this.resourceIndexStartValue
      : existingResourceRows;
    this.workerIndex = Number.isInteger(this.workerIndexStartValue)
      ? this.workerIndexStartValue
      : existingWorkerRows;
    // Use Stimulus values - they're automatically parsed from JSON
    this.inventories = this.inventoriesValue || [];
    this.workers = this.workersValue || [];
    // Store the current work order rate
    this.currentWorkOrderRate = 0;

    // Initialize current work order rate from the selected option on load (edit/new with preselected)
    this.initializeWorkOrderRateFromSelect();
    // Preserve per-worker saved rates on load; just refresh displays and amounts
    this.refreshAllWorkerDisplays();
    console.log("Loaded inventories:", this.inventories.length);
    console.log("Loaded workers:", this.workers.length);
  }

  initializeWorkOrderRateFromSelect() {
    try {
      // Find the select that holds work order rates (it has data-work-order-rates attribute)
      const rateSelect = this.element.querySelector(
        "select[data-work-order-rates]"
      );
      if (!rateSelect) return;

      const selectedId = rateSelect.value;
      const workOrderRates = JSON.parse(
        rateSelect.dataset.workOrderRates || "[]"
      );
      const selectedRate = workOrderRates.find(
        (rate) => rate.id?.toString() === selectedId
      );

      if (selectedRate) {
        const rateValue = parseFloat(selectedRate.rate) || 0;
        this.currentWorkOrderRate = rateValue;

        // Update header displays
        const rateDisplay = document.getElementById("work_order_rate_display");
        const unitDisplay = document.getElementById("work_order_unit_display");
        if (rateDisplay)
          rateDisplay.value =
            rateValue > 0 ? `RM ${rateValue.toFixed(2)}` : "N/A";
        if (unitDisplay)
          unitDisplay.value = selectedRate.unit
            ? selectedRate.unit.name
            : "N/A";

        // On initial load, do not overwrite saved per-worker rates
      }
    } catch (e) {
      console.warn("Failed to initialize work order rate from select", e);
    }
  }

  refreshAllWorkerDisplays() {
    const workerRows = this.workersContainerTarget.querySelectorAll(
      "tr[data-worker-index]"
    );
    workerRows.forEach((row) => {
      const index = row.dataset.workerIndex;
      const rateHidden = document.getElementById(`worker_rate_value_${index}`);
      const rateDisplay = document.getElementById(`worker_rate_${index}`);
      const rateVal = parseFloat(rateHidden?.value || "0");
      if (rateDisplay) {
        rateDisplay.value =
          rateVal > 0 ? `RM ${rateVal.toFixed(2)}` : "Auto Calculate";
      }
      this.calculateWorkerAmount(index);
    });
  }

  updateWorkOrderRate(event) {
    const select = event.target;
    const selectedId = select.value;

    if (!selectedId) {
      document.getElementById("work_order_rate_display").value = "Auto Filled";
      document.getElementById("work_order_unit_display").value = "Auto Filled";
      this.currentWorkOrderRate = 0;
      return;
    }

    try {
      const workOrderRates = JSON.parse(select.dataset.workOrderRates || "[]");
      const selectedRate = workOrderRates.find(
        (rate) => rate.id.toString() === selectedId
      );

      if (selectedRate) {
        const rateValue = parseFloat(selectedRate.rate) || 0;
        this.currentWorkOrderRate = rateValue;
        document.getElementById("work_order_rate_display").value =
          rateValue > 0 ? `RM ${rateValue.toFixed(2)}` : "N/A";
        document.getElementById("work_order_unit_display").value =
          selectedRate.unit ? selectedRate.unit.name : "N/A";

        // Update all existing worker rates
        this.updateAllWorkerRates();
      }
    } catch (error) {
      console.error("Error updating work order rate:", error);
    }
  }

  updateAllWorkerRates() {
    // Update rate for all existing worker rows
    const workerRows = this.workersContainerTarget.querySelectorAll(
      "tr[data-worker-index]"
    );
    workerRows.forEach((row) => {
      const index = row.dataset.workerIndex;
      const workerSelect = row.querySelector("select");
      if (workerSelect && workerSelect.value) {
        this.applyWorkerRate(index);
      }
    });
  }

  addResource() {
    if (!this.inventories || this.inventories.length === 0) {
      alert("No inventories available. Please add inventory items first.");
      return;
    }
    const row = this.createResourceRow(this.resourceIndex);
    this.resourcesContainerTarget.insertAdjacentHTML("beforeend", row);
    this.resourceIndex++;
  }

  createResourceRow(index) {
    const inventoryOptions = (this.inventories || [])
      .map(
        (inv) =>
          `<option value="${inv.id}" data-category="${
            inv.category?.name || ""
          }" data-price="${inv.price || 0}" data-unit="${
            inv.unit?.name || ""
          }">${inv.name}</option>`
      )
      .join("");

    return `
      <tr data-resource-index="${index}">
        <td>
          <select class="form-select form-select-sm" name="work_order[work_order_items_attributes][${index}][inventory_id]" onchange="window.workOrderFormController.updateResourceDetails(this, ${index})">
            <option value="">Select Resource</option>
            ${inventoryOptions}
          </select>
        </td>
        <td>
          <input type="text" class="form-control form-control-sm" id="resource_category_${index}" value="Auto Filled" disabled style="background-color: #e9ecef;">
        </td>
        <td>
          <input type="text" class="form-control form-control-sm" id="resource_price_${index}" value="Auto Filled" disabled style="background-color: #e9ecef;">
        </td>
        <td>
          <input type="text" class="form-control form-control-sm" id="resource_unit_${index}" value="Auto Filled" disabled style="background-color: #e9ecef;">
        </td>
        <td>
          <input type="number" class="form-control form-control-sm" name="work_order[work_order_items_attributes][${index}][amount_used]" placeholder="0" step="0.01" min="0">
        </td>
        <input type="hidden" id="resource_destroy_${index}" name="work_order[work_order_items_attributes][${index}][_destroy]" value="0">
        <td class="text-center">
          <button type="button" class="btn btn-danger btn-sm" onclick="window.workOrderFormController.removeResource(${index})">
            <i class="bi bi-trash"></i>
          </button>
        </td>
      </tr>
    `;
  }

  updateResourceDetails(select, index) {
    if (!select || !select.options || select.selectedIndex < 0) return;
    const selectedOption = select.options[select.selectedIndex];
    if (!selectedOption.value) {
      document.getElementById(`resource_category_${index}`).value =
        "Auto Filled";
      document.getElementById(`resource_price_${index}`).value = "Auto Filled";
      document.getElementById(`resource_unit_${index}`).value = "Auto Filled";
      return;
    }

    const category = selectedOption.dataset.category || "N/A";
    const price = selectedOption.dataset.price || "0";
    const unit = selectedOption.dataset.unit || "N/A";

    document.getElementById(`resource_category_${index}`).value = category;
    document.getElementById(`resource_price_${index}`).value = `RM ${parseFloat(
      price
    ).toFixed(2)}`;
    document.getElementById(`resource_unit_${index}`).value = unit;
  }

  addWorker() {
    if (!this.workers || this.workers.length === 0) {
      alert("No workers available. Please add worker records first.");
      return;
    }
    const row = this.createWorkerRow(this.workerIndex);
    this.workersContainerTarget.insertAdjacentHTML("beforeend", row);
    this.workerIndex++;
  }

  createWorkerRow(index) {
    const workerOptions = (this.workers || [])
      .map((worker) => `<option value="${worker.id}">${worker.name}</option>`)
      .join("");

    return `
      <tr data-worker-index="${index}">
        <td>
          <select class="form-select form-select-sm" name="work_order[work_order_workers_attributes][${index}][worker_id]" onchange="window.workOrderFormController.updateWorkerDetails(this, ${index})">
            <option value="">Select Worker</option>
            ${workerOptions}
          </select>
        </td>
        <td>
          <input type="number" class="form-control form-control-sm" id="worker_quantity_${index}" name="work_order[work_order_workers_attributes][${index}][work_area_size]" placeholder="0" step="0.01" min="0" oninput="window.workOrderFormController.calculateWorkerAmount(${index})">
        </td>
        <td>
          <input type="text" class="form-control form-control-sm" id="worker_rate_${index}" value="${
      this.currentWorkOrderRate > 0
        ? `RM ${this.currentWorkOrderRate.toFixed(2)}`
        : "Auto Calculate"
    }" disabled style="background-color: #e9ecef;">
          <input type="hidden" id="worker_rate_value_${index}" name="work_order[work_order_workers_attributes][${index}][rate]" value="${(
      this.currentWorkOrderRate || 0
    ).toFixed(2)}">
        </td>
        <td>
          <input type="text" class="form-control form-control-sm" id="worker_amount_${index}" value="Auto Calculate" disabled style="background-color: #e9ecef;">
          <input type="hidden" id="worker_amount_value_${index}" name="work_order[work_order_workers_attributes][${index}][amount]" value="0">
        </td>
        <td>
          <input type="text" class="form-control form-control-sm" name="work_order[work_order_workers_attributes][${index}][remarks]" placeholder="Remarks">
        </td>
        <input type="hidden" id="worker_destroy_${index}" name="work_order[work_order_workers_attributes][${index}][_destroy]" value="0">
        <td class="text-center">
          <button type="button" class="btn btn-danger btn-sm" onclick="window.workOrderFormController.removeWorker(${index})">
            <i class="bi bi-trash"></i>
          </button>
        </td>
      </tr>
    `;
  }

  updateWorkerDetails(select, index) {
    if (!select || !select.options || select.selectedIndex < 0) return;
    const selectedOption = select.options[select.selectedIndex];
    if (!selectedOption.value) {
      document.getElementById(`worker_rate_${index}`).value = "Auto Filled";
      document.getElementById(`worker_rate_value_${index}`).value = "0";
      document.getElementById(`worker_amount_${index}`).value =
        "Auto Calculate";
      document.getElementById(`worker_amount_value_${index}`).value = "0";
      return;
    }

    // Preserve existing rate; just recalc amount based on quantity and current hidden rate
    this.calculateWorkerAmount(index);
  }

  applyWorkerRate(index) {
    const rate = this.currentWorkOrderRate || 0;
    document.getElementById(`worker_rate_${index}`).value =
      rate > 0 ? `RM ${rate.toFixed(2)}` : "Auto Filled";
    document.getElementById(`worker_rate_value_${index}`).value =
      rate.toFixed(2);

    // Recalculate amount with the new rate
    this.calculateWorkerAmount(index);
  }

  calculateWorkerAmount(index) {
    const quantityEl = document.getElementById(`worker_quantity_${index}`);
    const rateEl = document.getElementById(`worker_rate_value_${index}`);
    const amountEl = document.getElementById(`worker_amount_${index}`);
    const amountValueEl = document.getElementById(`worker_amount_value_${index}`);

    const quantity = parseFloat(quantityEl?.value) || 0;
    const rate = parseFloat(rateEl?.value) || 0;
    const amount = quantity * rate;

    if (amountEl) {
      amountEl.value = `RM ${amount.toFixed(2)}`;
    }
    if (amountValueEl) {
      amountValueEl.value = amount.toFixed(2);
    }
  }
}

