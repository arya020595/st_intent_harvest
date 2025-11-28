import { Controller } from "@hotwired/stimulus";
import flatpickr from "flatpickr";

export default class extends Controller {
  static targets = ["input"];   // <-- REQUIRED
  static values = {
    mode: { type: String, default: "single" },
    dateFormat: { type: String, default: "Y-m-d" },
    enableTime: { type: Boolean, default: false },
    fieldName: { type: String, default: "" },
  };

  connect() {
    this.initializeFlatpickr();
    this.loadExistingDates();
  }

  open() {
    if (this.picker) this.picker.open();
  }

  disconnect() {
    this.destroyPicker();
  }

  initializeFlatpickr() {
    const config = this.buildFlatpickrConfig();
    this.picker = flatpickr(this.inputTarget, config); // <-- POINT TO INPUT
  }

  buildFlatpickrConfig() {
    const config = {
      mode: this.modeValue,
      dateFormat: this.dateFormatValue,
      enableTime: this.enableTimeValue,
      allowInput: true,
      clickOpens: true,
    };

    if (this.isRangeMode()) {
      config.onClose = this.handleRangeClose.bind(this);
    }

    return config;
  }

  handleRangeClose(selectedDates) {
    if (selectedDates.length === 2) {
      const [startDate, endDate] = selectedDates;
      this.syncRansackFields(startDate, endDate);
    } else {
      this.clearRansackFields();
    }
  }

  loadExistingDates() {
    if (!this.isRangeMode() || !this.hasFieldName()) return;

    const { gteqField, lteqField } = this.findRansackFields();

    if (gteqField?.value && lteqField?.value && this.picker) {
      const start = new Date(gteqField.value);
      const end = new Date(lteqField.value);
      this.picker.setDate([start, end], true);
    }
  }

  syncRansackFields(startDate, endDate) {
    const { gteqField, lteqField } = this.findRansackFields();
    if (gteqField) gteqField.value = this.formatDateForRansack(startDate);
    if (lteqField) lteqField.value = this.formatDateForRansack(endDate);
  }

  clearRansackFields() {
    const { gteqField, lteqField } = this.findRansackFields();
    if (gteqField) gteqField.value = "";
    if (lteqField) lteqField.value = "";
  }

  findRansackFields() {
    const form = this.element.closest("form");
    const baseId = this.normalizeFieldName();

    return {
      gteqField: form?.querySelector(`#${baseId}_gteq`),
      lteqField: form?.querySelector(`#${baseId}_lteq`),
    };
  }

  normalizeFieldName() {
    return this.fieldNameValue.replace(/\[/g, "_").replace(/\]/g, "");
  }

  formatDateForRansack(date) {
    return date.toISOString().split("T")[0];
  }

  isRangeMode() {
    return this.modeValue === "range";
  }

  hasFieldName() {
    return this.fieldNameValue.length > 0;
  }

  destroyPicker() {
    if (this.picker) this.picker.destroy();
  }
}
