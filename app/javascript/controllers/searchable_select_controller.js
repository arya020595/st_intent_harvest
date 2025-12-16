import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="searchable-select"
// Pure JavaScript searchable select implementation (no external dependencies)
// Styles are in app/assets/stylesheets/searchable_select.scss
export default class extends Controller {
  static values = {
    placeholder: { type: String, default: "Select an option..." },
    allowClear: { type: Boolean, default: true },
  };

  connect() {
    this.initializeSearchableSelect();
  }

  disconnect() {
    this.destroy();
  }

  initializeSearchableSelect() {
    // Don't reinitialize if already initialized
    if (this.wrapper) {
      return;
    }

    // Hide original select
    this.element.style.display = "none";

    // Build options from original select
    this.options = this.buildOptions();

    // Create wrapper
    this.wrapper = document.createElement("div");
    this.wrapper.className = "searchable-select-wrapper";

    // Create the custom select display
    this.display = document.createElement("div");
    this.display.className = "form-select searchable-select-display";
    this.display.tabIndex = 0;
    this.updateDisplayText();

    // Create clear button
    if (this.allowClearValue) {
      this.clearBtn = document.createElement("span");
      this.clearBtn.className = "searchable-select-clear";
      this.clearBtn.innerHTML = "&times;";
      this.clearBtn.addEventListener("click", (e) => {
        e.stopPropagation();
        this.clearSelection();
      });
    }

    // Create dropdown
    this.dropdown = document.createElement("div");
    this.dropdown.className = "searchable-select-dropdown";

    // Create search input
    this.searchInput = document.createElement("input");
    this.searchInput.type = "text";
    this.searchInput.className = "form-control searchable-select-search";
    this.searchInput.placeholder = "Type to search...";

    // Create options container
    this.optionsContainer = document.createElement("div");
    this.optionsContainer.className = "searchable-select-options";

    // Assemble dropdown
    this.dropdown.appendChild(this.searchInput);
    this.dropdown.appendChild(this.optionsContainer);

    // Assemble wrapper
    this.wrapper.appendChild(this.display);
    if (this.allowClearValue) {
      this.wrapper.appendChild(this.clearBtn);
    }

    // Insert after original select
    this.element.parentNode.insertBefore(
      this.wrapper,
      this.element.nextSibling
    );

    // Append dropdown to body to avoid overflow issues with table containers
    document.body.appendChild(this.dropdown);

    // Render options
    this.renderOptions();

    // Bind events
    this.bindEvents();

    // Update clear button visibility
    this.updateClearButton();
  }

  buildOptions() {
    const options = [];
    Array.from(this.element.options).forEach((opt) => {
      options.push({
        value: opt.value,
        text: opt.text,
        selected: opt.selected,
        disabled: opt.disabled,
      });
    });
    return options;
  }

  renderOptions(filter = "") {
    this.optionsContainer.innerHTML = "";
    const lowerFilter = filter.toLowerCase();

    let hasResults = false;
    this.options.forEach((opt) => {
      // Skip empty value (placeholder) option if there's a filter
      if (filter && opt.value === "") return;

      // Filter by search text
      if (lowerFilter && !opt.text.toLowerCase().includes(lowerFilter)) {
        return;
      }

      hasResults = true;
      const optionEl = document.createElement("div");
      optionEl.className = "searchable-select-option";
      optionEl.dataset.value = opt.value;
      optionEl.textContent = opt.text;

      if (this.element.value === opt.value && opt.value !== "") {
        optionEl.classList.add("selected");
      }

      optionEl.addEventListener("click", () => {
        this.selectOption(opt.value, opt.text);
      });

      this.optionsContainer.appendChild(optionEl);
    });

    // Show "no results" message
    if (!hasResults && filter) {
      const noResults = document.createElement("div");
      noResults.className = "searchable-select-no-results";
      noResults.textContent = `No results found for "${filter}"`;
      this.optionsContainer.appendChild(noResults);
    }
  }

  bindEvents() {
    // Toggle dropdown on display click
    this.display.addEventListener("click", () => {
      this.toggleDropdown();
    });

    // Keyboard navigation on display
    this.display.addEventListener("keydown", (e) => {
      if (e.key === "Enter" || e.key === " ") {
        e.preventDefault();
        this.toggleDropdown();
      } else if (e.key === "Escape") {
        this.closeDropdown();
      }
    });

    // Search input filtering
    this.searchInput.addEventListener("input", () => {
      this.renderOptions(this.searchInput.value);
    });

    // Prevent dropdown close when clicking search input
    this.searchInput.addEventListener("click", (e) => {
      e.stopPropagation();
    });

    // Keyboard navigation in search input
    this.searchInput.addEventListener("keydown", (e) => {
      if (e.key === "Escape") {
        this.closeDropdown();
      } else if (e.key === "Enter") {
        const firstOption = this.optionsContainer.querySelector(
          ".searchable-select-option:not(.selected)"
        );
        if (firstOption) {
          firstOption.click();
        }
      }
    });

    // Close dropdown when clicking outside
    this.outsideClickHandler = (e) => {
      if (
        !this.wrapper.contains(e.target) &&
        !this.dropdown.contains(e.target)
      ) {
        this.closeDropdown();
      }
    };
    document.addEventListener("click", this.outsideClickHandler);

    // Reposition dropdown on scroll/resize
    this.repositionHandler = () => {
      if (this.dropdown.style.display === "block") {
        this.positionDropdown();
      }
    };
    window.addEventListener("scroll", this.repositionHandler, true);
    window.addEventListener("resize", this.repositionHandler);
  }

  toggleDropdown() {
    if (this.dropdown.style.display === "none") {
      this.openDropdown();
    } else {
      this.closeDropdown();
    }
  }

  positionDropdown() {
    const rect = this.display.getBoundingClientRect();
    const dropdownHeight = 250; // max-height of dropdown
    const spaceBelow = window.innerHeight - rect.bottom;
    const spaceAbove = rect.top;

    // Position dropdown below or above based on available space
    if (spaceBelow >= dropdownHeight || spaceBelow >= spaceAbove) {
      this.dropdown.style.top = `${rect.bottom}px`;
    } else {
      this.dropdown.style.top = `${
        rect.top - Math.min(dropdownHeight, spaceAbove)
      }px`;
    }

    this.dropdown.style.left = `${rect.left}px`;
    this.dropdown.style.width = `${rect.width}px`;
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

  selectOption(value, text) {
    // Update original select
    this.element.value = value;

    // Trigger change event
    this.element.dispatchEvent(new Event("change", { bubbles: true }));

    // Update display
    this.updateDisplayText();

    // Update clear button visibility
    this.updateClearButton();

    // Close dropdown
    this.closeDropdown();

    // Re-render to update selected styling
    this.renderOptions();
  }

  clearSelection() {
    // Find the blank/placeholder option
    const blankOption = this.options.find((opt) => opt.value === "");
    if (blankOption) {
      this.selectOption(blankOption.value, blankOption.text);
    } else {
      this.element.value = "";
      this.element.dispatchEvent(new Event("change", { bubbles: true }));
      this.updateDisplayText();
      this.updateClearButton();
    }
  }

  updateDisplayText() {
    const selectedOption = this.options.find(
      (opt) => opt.value === this.element.value
    );
    if (selectedOption && selectedOption.value !== "") {
      this.display.textContent = selectedOption.text;
      this.display.classList.remove("placeholder");
    } else {
      this.display.textContent = this.placeholderValue;
      this.display.classList.add("placeholder");
    }
  }

  updateClearButton() {
    if (this.clearBtn) {
      if (this.element.value && this.element.value !== "") {
        this.clearBtn.style.display = "block";
      } else {
        this.clearBtn.style.display = "none";
      }
    }
  }

  // Public method to refresh options (e.g., when options change dynamically)
  refresh() {
    this.options = this.buildOptions();
    this.renderOptions();
    this.updateDisplayText();
    this.updateClearButton();
  }

  destroy() {
    if (this.outsideClickHandler) {
      document.removeEventListener("click", this.outsideClickHandler);
    }
    if (this.repositionHandler) {
      window.removeEventListener("scroll", this.repositionHandler, true);
      window.removeEventListener("resize", this.repositionHandler);
    }
    if (this.dropdown && this.dropdown.parentNode) {
      this.dropdown.remove();
    }
    if (this.wrapper) {
      this.wrapper.remove();
    }
    if (this.element) {
      this.element.style.display = "";
    }
    this.wrapper = null;
    this.dropdown = null;
  }
}
