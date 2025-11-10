import { Controller } from "@hotwired/stimulus";
import flatpickr from "flatpickr";

/**
 * Flatpickr Controller
 * 
 * A reusable Stimulus controller for date/datetime picking with Flatpickr library.
 * Supports single date, multiple dates, and date range modes.
 * Automatically syncs with Ransack hidden fields for Rails search forms.
 * 
 * @example Basic usage (single date)
 *   <input type="text" 
 *          data-controller="flatpickr"
 *          data-flatpickr-date-format-value="d-m-Y">
 * 
 * @example Range mode with Ransack integration
 *   <input type="text" 
 *          data-controller="flatpickr"
 *          data-flatpickr-mode-value="range"
 *          data-flatpickr-date-format-value="d-m-Y"
 *          data-flatpickr-field-name-value="q[hired_date]">
 *   <%= f.hidden_field :hired_date_gteq %>
 *   <%= f.hidden_field :hired_date_lteq %>
 * 
 * @example With time picker
 *   <input type="text" 
 *          data-controller="flatpickr"
 *          data-flatpickr-enable-time-value="true"
 *          data-flatpickr-date-format-value="d-m-Y H:i">
 */
export default class extends Controller {
  static values = {
    mode: { type: String, default: "single" }, // single, multiple, range
    dateFormat: { type: String, default: "Y-m-d" }, // Display format
    enableTime: { type: Boolean, default: false }, // Enable time picker
    fieldName: { type: String, default: "" }, // For Ransack integration (e.g., "q[hired_date]")
  };

  /**
   * Lifecycle: Called when controller is connected to DOM
   */
  connect() {
    this.initializeFlatpickr();
    this.loadExistingDates();
  }

  /**
   * Lifecycle: Called when controller is disconnected from DOM
   * Cleanup to prevent memory leaks
   */
  disconnect() {
    this.destroyPicker();
  }

  /**
   * Initialize Flatpickr instance with configuration
   * @private
   */
  initializeFlatpickr() {
    const config = this.buildFlatpickrConfig();
    this.picker = flatpickr(this.element, config);
  }

  /**
   * Build Flatpickr configuration object
   * @private
   * @returns {Object} Flatpickr configuration
   */
  buildFlatpickrConfig() {
    const config = {
      mode: this.modeValue,
      dateFormat: this.dateFormatValue,
      enableTime: this.enableTimeValue,
      allowInput: true,
      clickOpens: true,
    };

    // Add range-specific handlers
    if (this.isRangeMode()) {
      config.onClose = this.handleRangeClose.bind(this);
    }

    return config;
  }

  /**
   * Handle date range selection completion
   * @private
   * @param {Array<Date>} selectedDates - Array of selected dates
   */
  handleRangeClose(selectedDates) {
    if (selectedDates.length === 2) {
      const [startDate, endDate] = selectedDates;
      this.syncRansackFields(startDate, endDate);
    } else if (selectedDates.length === 0) {
      this.clearRansackFields();
    }
  }

  /**
   * Load existing dates from hidden fields (for page reload/back button)
   * @private
   */
  loadExistingDates() {
    if (!this.isRangeMode() || !this.hasFieldName()) {
      return;
    }

    const { gteqField, lteqField } = this.findRansackFields();

    if (gteqField?.value && lteqField?.value && this.picker) {
      const startDate = new Date(gteqField.value);
      const endDate = new Date(lteqField.value);
      this.picker.setDate([startDate, endDate], true);
    }
  }

  /**
   * Sync selected date range to Ransack hidden fields
   * @private
   * @param {Date} startDate - Range start date
   * @param {Date} endDate - Range end date
   */
  syncRansackFields(startDate, endDate) {
    const { gteqField, lteqField } = this.findRansackFields();

    if (gteqField && lteqField) {
      gteqField.value = this.formatDateForRansack(startDate);
      lteqField.value = this.formatDateForRansack(endDate);
    }
  }

  /**
   * Clear Ransack hidden fields
   * @private
   */
  clearRansackFields() {
    const { gteqField, lteqField } = this.findRansackFields();

    if (gteqField) gteqField.value = "";
    if (lteqField) lteqField.value = "";
  }

  /**
   * Find Ransack gteq/lteq hidden fields in the form
   * @private
   * @returns {Object} Object containing gteqField and lteqField elements
   */
  findRansackFields() {
    const form = this.element.closest("form");
    const baseId = this.normalizeFieldName();

    return {
      gteqField: form?.querySelector(`input[id="${baseId}_gteq"]`),
      lteqField: form?.querySelector(`input[id="${baseId}_lteq"]`),
    };
  }

  /**
   * Normalize field name to match Rails form field ID format
   * Converts "q[hired_date]" to "q_hired_date"
   * @private
   * @returns {string} Normalized field name
   */
  normalizeFieldName() {
    return this.fieldNameValue.replace(/\[/g, "_").replace(/\]/g, "");
  }

  /**
   * Format date for Ransack (YYYY-MM-DD)
   * @private
   * @param {Date} date - Date to format
   * @returns {string} Formatted date string
   */
  formatDateForRansack(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, "0");
    const day = String(date.getDate()).padStart(2, "0");
    return `${year}-${month}-${day}`;
  }

  /**
   * Check if controller is in range mode
   * @private
   * @returns {boolean}
   */
  isRangeMode() {
    return this.modeValue === "range";
  }

  /**
   * Check if field name is configured (for Ransack integration)
   * @private
   * @returns {boolean}
   */
  hasFieldName() {
    return this.fieldNameValue.length > 0;
  }

  /**
   * Destroy Flatpickr instance
   * @private
   */
  destroyPicker() {
    if (this.picker) {
      this.picker.destroy();
      this.picker = null;
    }
  }
}
