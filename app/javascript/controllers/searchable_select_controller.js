import { Controller } from "@hotwired/stimulus";

/**
 * Searchable Select Controller
 *
 * A pure JavaScript searchable dropdown implementation for Stimulus.
 * No external dependencies required.
 *
 * Features:
 * - Live search filtering
 * - Keyboard navigation
 * - Optional clear button
 * - Automatic detection of option additions/removals (via MutationObserver)
 *
 * Usage:
 *   <select data-controller="searchable-select"
 *           data-searchable-select-placeholder-value="Select..."
 *           data-searchable-select-allow-clear-value="true">
 *
 * The controller automatically detects when options are added or removed in the
 * underlying select element. If you need to manually trigger a refresh, you can
 * call the `refresh()` method on the controller instance.
 *
 * Styles: app/assets/stylesheets/searchable_select.scss
 */
export default class extends Controller {
  static values = {
    placeholder: { type: String, default: "Select an option..." },
    allowClear: { type: Boolean, default: true },
  };

  // Debounce delay for batching rapid option changes (in milliseconds)
  // Can be increased (e.g., 50ms) if dealing with very frequent DOM updates
  static DEBOUNCE_DELAY = 10;

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
    this.highlightedIndex = -1;

    // Generate unique IDs for ARIA relationships
    this.uniqueId = `searchable-select-${Math.random()
      .toString(36)
      .substr(2, 9)}`;

    this.createWrapper();
    this.createDisplay();
    this.createClearButton();
    this.createDropdown();
    this.assembleElements();
    this.bindEvents();
    this.updateClearButton();
    this.observeSelectChanges();
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

    // ARIA attributes for combobox pattern
    this.display.setAttribute("role", "combobox");
    this.display.setAttribute("aria-haspopup", "listbox");
    this.display.setAttribute("aria-expanded", "false");
    this.display.id = `${this.uniqueId}-display`;
    this.display.setAttribute("aria-controls", `${this.uniqueId}-listbox`);

    // Copy label association from original select if present
    const label = document.querySelector(`label[for="${this.element.id}"]`);
    if (label) {
      this.display.setAttribute(
        "aria-labelledby",
        label.id || `${this.uniqueId}-label`
      );
      if (!label.id) label.id = `${this.uniqueId}-label`;
    }

    this.updateDisplayText();
  }

  createClearButton() {
    if (!this.allowClearValue) return;

    this.clearBtn = document.createElement("span");
    this.clearBtn.className = "searchable-select-clear";
    this.clearBtn.innerHTML = "&times;";
    this.clearBtn.setAttribute("role", "button");
    this.clearBtn.setAttribute("aria-label", "Clear selection");
    this.clearBtn.tabIndex = 0;

    // Keyboard accessibility: trigger clear on Enter/Space
    this.clearBtn.addEventListener("keydown", (e) => {
      if (e.key === "Enter" || e.key === " ") {
        e.preventDefault();
        e.stopPropagation();
        this.clearSelection();
      }
    });
  }

  createDropdown() {
    this.dropdown = document.createElement("div");
    this.dropdown.className = "searchable-select-dropdown";
    this.dropdown.setAttribute("role", "dialog");
    this.dropdown.setAttribute("aria-label", "Search options");

    this.searchInput = document.createElement("input");
    this.searchInput.type = "text";
    this.searchInput.className = "form-control searchable-select-search";
    this.searchInput.placeholder = "Type to search...";
    this.searchInput.id = `${this.uniqueId}-search`;
    this.searchInput.setAttribute("aria-label", "Search options");
    this.searchInput.setAttribute("aria-controls", `${this.uniqueId}-listbox`);
    this.searchInput.setAttribute("aria-autocomplete", "list");

    this.optionsContainer = document.createElement("div");
    this.optionsContainer.className = "searchable-select-options";
    this.optionsContainer.id = `${this.uniqueId}-listbox`;
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
    this.wrapper.appendChild(this.dropdown);
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

    this.options.forEach((opt) => {
      if (filter && opt.value === "") return;
      if (lowerFilter && !opt.text.toLowerCase().includes(lowerFilter)) return;

      hasResults = true;
      const optionEl = document.createElement("div");
      optionEl.className = "searchable-select-option";
      optionEl.dataset.value = opt.value;
      optionEl.textContent = opt.text;
      optionEl.id = `${this.uniqueId}-option-${this.optionsContainer.children.length}`;
      optionEl.setAttribute("role", "option");

      const isSelected = this.element.value === opt.value && opt.value !== "";
      if (isSelected) {
        optionEl.classList.add("selected");
        optionEl.setAttribute("aria-selected", "true");
      } else {
        optionEl.setAttribute("aria-selected", "false");
      }

      optionEl.addEventListener("click", () => this.selectOption(opt.value));
      optionEl.addEventListener("mouseenter", () => {
        this.highlightOptionByElement(optionEl);
      });
      this.optionsContainer.appendChild(optionEl);
    });

    if (!hasResults && filter) {
      const noResults = document.createElement("div");
      noResults.className = "searchable-select-no-results";
      noResults.textContent = `No results found for "${filter}"`;
      noResults.setAttribute("role", "status");
      noResults.setAttribute("aria-live", "polite");
      this.optionsContainer.appendChild(noResults);
    }

    this.highlightedIndex = -1;
    this.updateActiveDescendant();
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
      } else if (e.key === "ArrowDown") {
        e.preventDefault();
        if (!this.isOpen()) {
          this.openDropdown();
        } else {
          this.highlightNextOption();
        }
      } else if (e.key === "ArrowUp") {
        e.preventDefault();
        if (!this.isOpen()) {
          this.openDropdown();
        } else {
          this.highlightPreviousOption();
        }
      }
    });

    this.searchInput.addEventListener("input", () => {
      this.renderOptions(this.searchInput.value);
      // Reposition dropdown after filtering since height may change
      this.positionDropdown();
    });

    this.searchInput.addEventListener("click", (e) => e.stopPropagation());

    this.searchInput.addEventListener("keydown", (e) => {
      if (e.key === "Escape") {
        this.closeDropdown();
        this.display.focus();
      } else if (e.key === "Tab") {
        // Allow natural tab behavior but close dropdown
        this.closeDropdown();
      } else if (e.key === "ArrowDown") {
        e.preventDefault();
        this.highlightNextOption();
      } else if (e.key === "ArrowUp") {
        e.preventDefault();
        this.highlightPreviousOption();
      } else if (e.key === "Enter") {
        e.preventDefault();
        this.selectHighlightedOption();
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
    this.highlightedIndex = -1;
    this.updateActiveDescendant();
    this.searchInput.focus();
  }

  closeDropdown() {
    this.dropdown.style.display = "none";
    this.display.setAttribute("aria-expanded", "false");
    this.updateActiveDescendant();
  }

  positionDropdown() {
    const rect = this.display.getBoundingClientRect();
    const maxDropdownHeight = 250;
    const spaceBelow = window.innerHeight - rect.bottom;
    const spaceAbove = rect.top;

    // Temporarily show dropdown to measure actual height
    const wasHidden = this.dropdown.style.display === "none";
    if (wasHidden) {
      this.dropdown.style.visibility = "hidden";
      this.dropdown.style.display = "block";
    }

    // Get actual dropdown height (capped at max)
    const actualHeight = Math.min(
      this.dropdown.offsetHeight,
      maxDropdownHeight
    );

    if (wasHidden) {
      this.dropdown.style.display = "none";
      this.dropdown.style.visibility = "";
    }

    // Decide whether to open above or below
    const openBelow = spaceBelow >= actualHeight || spaceBelow >= spaceAbove;

    if (openBelow) {
      this.dropdown.style.top = `${rect.bottom}px`;
    } else {
      this.dropdown.style.top = `${rect.top - actualHeight}px`;
    }

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

  // === Keyboard Navigation ===

  highlightNextOption() {
    const options = this.getVisibleOptions();
    if (options.length === 0) return;

    if (this.highlightedIndex < 0) {
      // Nothing highlighted yet, start at first option
      this.highlightedIndex = 0;
    } else {
      this.highlightedIndex = Math.min(
        this.highlightedIndex + 1,
        options.length - 1
      );
    }
    this.updateHighlight(options);
  }

  highlightPreviousOption() {
    const options = this.getVisibleOptions();
    if (options.length === 0) return;

    if (this.highlightedIndex < 0) {
      // Nothing highlighted yet, start at last option
      this.highlightedIndex = options.length - 1;
    } else if (this.highlightedIndex > 0) {
      this.highlightedIndex = this.highlightedIndex - 1;
    }
    // If already at 0, stay there
    this.updateHighlight(options);
  }

  highlightOptionByElement(optionEl) {
    const options = this.getVisibleOptions();
    const index = options.indexOf(optionEl);
    if (index !== -1) {
      this.highlightedIndex = index;
      this.updateHighlight(options);
    }
  }

  updateHighlight(options) {
    options.forEach((opt, idx) => {
      if (idx === this.highlightedIndex) {
        opt.classList.add("highlighted");
        opt.scrollIntoView({ block: "nearest", behavior: "auto" });
      } else {
        opt.classList.remove("highlighted");
      }
    });
    this.updateActiveDescendant();
  }

  updateActiveDescendant() {
    const options = this.getVisibleOptions();
    const highlighted = options[this.highlightedIndex];

    if (highlighted && this.isOpen()) {
      this.searchInput.setAttribute("aria-activedescendant", highlighted.id);
      this.display.setAttribute("aria-activedescendant", highlighted.id);
    } else {
      this.searchInput.removeAttribute("aria-activedescendant");
      this.display.removeAttribute("aria-activedescendant");
    }
  }

  getVisibleOptions() {
    return Array.from(
      this.optionsContainer.querySelectorAll(".searchable-select-option")
    );
  }

  selectHighlightedOption() {
    const options = this.getVisibleOptions();
    if (this.highlightedIndex >= 0 && this.highlightedIndex < options.length) {
      const highlightedOption = options[this.highlightedIndex];
      const value = highlightedOption.dataset.value;
      this.selectOption(value);
    }
  }

  // === Public API ===

  refresh() {
    this.options = this.buildOptions();
    this.renderOptions();
    this.updateDisplayText();
    this.updateClearButton();
  }

  // === MutationObserver ===

  hasMutatedOptions(mutations) {
    // Check if any mutations involve option elements
    return mutations.some((mutation) => {
      // Check if added or removed nodes include option elements
      const hasAddedOptions = Array.from(mutation.addedNodes).some(
        (node) =>
          node.nodeType === Node.ELEMENT_NODE && node.nodeName === "OPTION"
      );
      const hasRemovedOptions = Array.from(mutation.removedNodes).some(
        (node) =>
          node.nodeType === Node.ELEMENT_NODE && node.nodeName === "OPTION"
      );
      return hasAddedOptions || hasRemovedOptions;
    });
  }

  observeSelectChanges() {
    // Watch for changes to the select element's children (options)
    this.selectObserver = new MutationObserver((mutations) => {
      if (this.hasMutatedOptions(mutations)) {
        // Clear any pending refresh to debounce multiple rapid changes
        if (this.refreshTimeout) {
          clearTimeout(this.refreshTimeout);
        }

        // Schedule refresh with a small delay to batch multiple changes
        this.refreshTimeout = setTimeout(() => {
          this.refresh();
          this.refreshTimeout = null;
        }, this.constructor.DEBOUNCE_DELAY);
      }
    });

    // Observe the select element for direct children changes only
    this.selectObserver.observe(this.element, {
      childList: true, // Watch for added/removed options
    });
  }

  // === Cleanup ===

  destroy() {
    if (this.refreshTimeout) {
      clearTimeout(this.refreshTimeout);
      this.refreshTimeout = null;
    }
    if (this.selectObserver) {
      this.selectObserver.disconnect();
      this.selectObserver = null;
    }
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
