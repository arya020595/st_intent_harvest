// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";

// Import Popper.js first (required for Bootstrap dropdowns, popovers, tooltips)
import "@popperjs/core";

// Bootstrap JavaScript - auto-initializes data-bs-* attributes
import "bootstrap";

// Custom Turbo Stream action to close Bootstrap modals
import { StreamActions } from "@hotwired/turbo";

// Hide all open Bootstrap modals (used for authorization errors)
StreamActions.hide_modals = function () {
  if (!window.bootstrap?.Modal) {
    console.warn("Bootstrap Modal not available");
    return;
  }

  const modals = document.querySelectorAll(".modal");
  modals.forEach((modal) => {
    const instance = bootstrap.Modal.getInstance(modal);
    if (instance) instance.hide();
  });
};
