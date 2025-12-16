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
 * - Automatic detection of option changes (via MutationObserver)
 *
 * Usage:
 *   <select data-controller="searchable-select"
 *           data-searchable-select-placeholder-value="Select..."
 *           data-searchable-select-allow-clear-value="true">
 *
 * The controller automatically detects when options are added, removed, or modified
 * in the underlying select element. If you need to manually trigger a refresh, you can
 * call the `refresh()` method on the controller instance.
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

    this.optionsContainer = document.createElement("div");
    this.optionsContainer.className = "searchable-select-options";

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

    this.options.forEach((opt) => {
      if (filter && opt.value === "") return;
      if (lowerFilter && !opt.text.toLowerCase().includes(lowerFilter)) return;

      hasResults = true;
      const optionEl = document.createElement("div");
      optionEl.className = "searchable-select-option";
      optionEl.dataset.value = opt.value;
      optionEl.textContent = opt.text;

      if (this.element.value === opt.value && opt.value !== "") {
        optionEl.classList.add("selected");
      }

      optionEl.addEventListener("click", () => this.selectOption(opt.value));
      this.optionsContainer.appendChild(optionEl);
    });

    if (!hasResults && filter) {
      const noResults = document.createElement("div");
      noResults.className = "searchable-select-no-results";
      noResults.textContent = `No results found for "${filter}"`;
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
    this.searchInput.value = "";
    this.renderOptions();
    this.searchInput.focus();
  }

  closeDropdown() {
    this.dropdown.style.display = "none";
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

  // === MutationObserver ===

  observeSelectChanges() {
    // Watch for changes to the select element's children (options)
    this.selectObserver = new MutationObserver((mutations) => {
      // Check if any of the mutations involved option changes
      const hasOptionChanges = mutations.some((mutation) => {
        return mutation.type === "childList";
      });

      if (hasOptionChanges) {
        // Clear any pending refresh to debounce multiple rapid changes
        if (this.refreshTimeout) {
          clearTimeout(this.refreshTimeout);
        }
        
        // Schedule refresh with a small delay to batch multiple changes
        this.refreshTimeout = setTimeout(() => {
          this.refresh();
          this.refreshTimeout = null;
        }, 10);
      }
    });

    // Observe the select element for changes to its children
    this.selectObserver.observe(this.element, {
      childList: true, // Watch for added/removed options
      subtree: true, // Watch changes in all descendants
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
