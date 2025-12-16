import { Controller } from "@hotwired/stimulus";

/**
 * Searchable Select Controller
 *
 * A pure JavaScript searchable dropdown implementation for Stimulus.
 * No external dependencies required.
 *
 * Usage:
 *   <select data-controller="searchable-select"
 *           data-searchable-select-placeholder-value="Select..."
 *           data-searchable-select-allow-clear-value="true">
 *
 * Styles: app/assets/stylesheets/searchable_select.scss
 */
export default class extends Controller {
  static values = {
    placeholder: { type: String, default: "Select an option..." },
    allowClear: { type: Boolean, default: true },
  };

  connect() {
    this.initialize();
  }

  disconnect() {
    this.destroy();
  }

  initialize() {
    if (this.wrapper) return;

    this.element.style.display = "none";
    this.options = this.buildOptions();

    this.createWrapper();
    this.createDisplay();
    this.createClearButton();
    this.createDropdown();
    this.assembleElements();
    this.bindEvents();
    this.updateClearButton();
  }

  // === Element Creation ===

  createWrapper() {
    this.wrapper = document.createElement("div");
    this.wrapper.className = "searchable-select-wrapper";
  }

  createDisplay() {
    this.display = document.createElement("div");
    this.display.className = "form-select searchable-select-display";
    this.display.tabIndex = 0;
    this.display.setAttribute("role", "combobox");
    this.display.setAttribute("aria-expanded", "false");
    this.display.setAttribute("aria-haspopup", "listbox");
    this.display.setAttribute("aria-label", this.placeholderValue);
    this.updateDisplayText();
  }

  createClearButton() {
    if (!this.allowClearValue) return;

    this.clearBtn = document.createElement("span");
    this.clearBtn.className = "searchable-select-clear";
    this.clearBtn.innerHTML = "&times;";
  }

  createDropdown() {
    this.dropdown = document.createElement("div");
    this.dropdown.className = "searchable-select-dropdown";

    this.searchInput = document.createElement("input");
    this.searchInput.type = "text";
    this.searchInput.className = "form-control searchable-select-search";
    this.searchInput.placeholder = "Type to search...";
    this.searchInput.setAttribute("role", "searchbox");
    this.searchInput.setAttribute("aria-label", "Search options");

    this.optionsContainer = document.createElement("div");
    this.optionsContainer.className = "searchable-select-options";
    this.optionsContainer.setAttribute("role", "listbox");
    this.optionsContainer.setAttribute("aria-label", "Available options");

    this.dropdown.appendChild(this.searchInput);
    this.dropdown.appendChild(this.optionsContainer);
  }

  assembleElements() {
    this.wrapper.appendChild(this.display);
    if (this.clearBtn) {
      this.wrapper.appendChild(this.clearBtn);
    }
    this.element.parentNode.insertBefore(
      this.wrapper,
      this.element.nextSibling
    );
    document.body.appendChild(this.dropdown);
    this.renderOptions();
  }

  // === Options ===

  buildOptions() {
    return Array.from(this.element.options).map((opt) => ({
      value: opt.value,
      text: opt.text,
    }));
  }

  renderOptions(filter = "") {
    this.optionsContainer.innerHTML = "";
    const lowerFilter = filter.toLowerCase();
    let hasResults = false;
    let selectedOptionId = null;

    this.options.forEach((opt, index) => {
      if (filter && opt.value === "") return;
      if (lowerFilter && !opt.text.toLowerCase().includes(lowerFilter)) return;

      hasResults = true;
      const optionEl = document.createElement("div");
      const optionId = `searchable-option-${index}`;
      optionEl.className = "searchable-select-option";
      optionEl.dataset.value = opt.value;
      optionEl.textContent = opt.text;
      optionEl.setAttribute("role", "option");
      optionEl.setAttribute("id", optionId);

      if (this.element.value === opt.value && opt.value !== "") {
        optionEl.classList.add("selected");
        optionEl.setAttribute("aria-selected", "true");
        selectedOptionId = optionId;
      } else {
        optionEl.setAttribute("aria-selected", "false");
      }

      optionEl.addEventListener("click", () => this.selectOption(opt.value));
      this.optionsContainer.appendChild(optionEl);
    });

    // Update aria-activedescendant on the display element
    if (selectedOptionId) {
      this.display.setAttribute("aria-activedescendant", selectedOptionId);
    } else {
      this.display.removeAttribute("aria-activedescendant");
    }

    if (!hasResults && filter) {
      const noResults = document.createElement("div");
      noResults.className = "searchable-select-no-results";
      noResults.textContent = `No results found for "${filter}"`;
      noResults.setAttribute("role", "status");
      noResults.setAttribute("aria-live", "polite");
      this.optionsContainer.appendChild(noResults);
    }
  }

  // === Events ===

  bindEvents() {
    this.display.addEventListener("click", () => this.toggleDropdown());

    this.display.addEventListener("keydown", (e) => {
      if (e.key === "Enter" || e.key === " ") {
        e.preventDefault();
        this.toggleDropdown();
      } else if (e.key === "Escape") {
        this.closeDropdown();
      }
    });

    this.searchInput.addEventListener("input", () => {
      this.renderOptions(this.searchInput.value);
    });

    this.searchInput.addEventListener("click", (e) => e.stopPropagation());

    this.searchInput.addEventListener("keydown", (e) => {
      if (e.key === "Escape") {
        this.closeDropdown();
      } else if (e.key === "Enter") {
        const firstOption = this.optionsContainer.querySelector(
          ".searchable-select-option:not(.selected)"
        );
        if (firstOption) firstOption.click();
      }
    });

    if (this.clearBtn) {
      this.clearBtn.addEventListener("click", (e) => {
        e.stopPropagation();
        this.clearSelection();
      });
    }

    this.outsideClickHandler = (e) => {
      if (
        !this.wrapper.contains(e.target) &&
        !this.dropdown.contains(e.target)
      ) {
        this.closeDropdown();
      }
    };
    document.addEventListener("click", this.outsideClickHandler);

    this.repositionHandler = () => {
      if (this.isOpen()) this.positionDropdown();
    };
    window.addEventListener("scroll", this.repositionHandler, true);
    window.addEventListener("resize", this.repositionHandler);
  }

  // === Dropdown Control ===

  isOpen() {
    return getComputedStyle(this.dropdown).display !== "none";
  }

  toggleDropdown() {
    this.isOpen() ? this.closeDropdown() : this.openDropdown();
  }

  openDropdown() {
    this.positionDropdown();
    this.dropdown.style.display = "block";
    this.display.setAttribute("aria-expanded", "true");
    this.searchInput.value = "";
    this.renderOptions();
    this.searchInput.focus();
  }

  closeDropdown() {
    this.dropdown.style.display = "none";
    this.display.setAttribute("aria-expanded", "false");
  }

  positionDropdown() {
    const rect = this.display.getBoundingClientRect();
    const dropdownHeight = 250;
    const spaceBelow = window.innerHeight - rect.bottom;

    this.dropdown.style.top =
      spaceBelow >= dropdownHeight || spaceBelow >= rect.top
        ? `${rect.bottom}px`
        : `${rect.top - Math.min(dropdownHeight, rect.top)}px`;

    this.dropdown.style.left = `${rect.left}px`;
    this.dropdown.style.width = `${rect.width}px`;
  }

  // === Selection ===

  selectOption(value) {
    this.element.value = value;
    this.element.dispatchEvent(new Event("change", { bubbles: true }));
    this.updateDisplayText();
    this.updateClearButton();
    this.closeDropdown();
    this.renderOptions();
  }

  clearSelection() {
    const blankOption = this.options.find((opt) => opt.value === "");
    this.selectOption(blankOption ? blankOption.value : "");
  }

  updateDisplayText() {
    const selected = this.options.find(
      (opt) => opt.value === this.element.value
    );
    if (selected && selected.value !== "") {
      this.display.textContent = selected.text;
      this.display.classList.remove("placeholder");
    } else {
      this.display.textContent = this.placeholderValue;
      this.display.classList.add("placeholder");
    }
  }

  updateClearButton() {
    if (!this.clearBtn) return;
    this.clearBtn.style.display =
      this.element.value && this.element.value !== "" ? "block" : "none";
  }

  // === Public API ===

  refresh() {
    this.options = this.buildOptions();
    this.renderOptions();
    this.updateDisplayText();
    this.updateClearButton();
  }

  // === Cleanup ===

  destroy() {
    if (this.outsideClickHandler) {
      document.removeEventListener("click", this.outsideClickHandler);
    }
    if (this.repositionHandler) {
      window.removeEventListener("scroll", this.repositionHandler, true);
      window.removeEventListener("resize", this.repositionHandler);
    }
    this.dropdown?.remove();
    this.wrapper?.remove();
    if (this.element) {
      this.element.style.display = "";
    }
    this.wrapper = null;
    this.dropdown = null;
  }
}
