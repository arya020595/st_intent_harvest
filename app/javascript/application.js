// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Import Popper.js first (required for Bootstrap dropdowns, popovers, tooltips)
// import "@popperjs/core"

// Bootstrap JavaScript - auto-initializes data-bs-* attributes
import "bootstrap"

// Global sidebar toggle and close functionality
function initSidebar() {
  document.addEventListener("click", (event) => {
    // Toggle sidebar when hamburger (#sidebarToggle) is clicked
    const sidebarToggle = event.target.closest("#sidebarToggle")
    if (sidebarToggle) {
      const sidebar = document.getElementById("sidebar")
      if (sidebar) {
        sidebar.classList.toggle("sidebar-collapsed")
      }
      return
    }

    // When a regular link inside the sidebar is clicked, close the sidebar
    const anchor = event.target.closest("a")
    if (!anchor) return

    const sidebar = document.getElementById("sidebar")
    if (!sidebar) return

    // Only consider clicks on links inside the sidebar
    if (!anchor.closest("#sidebar")) return

    // Ignore collapse toggles and placeholder links
    if (anchor.dataset.bsToggle || anchor.getAttribute("href") === "#") return

    // Close sidebar
    if (sidebar.classList.contains("sidebar-collapsed")) {
      sidebar.classList.remove("sidebar-collapsed")
    }
  })
}

function closeSidebarOnNavigation() {
  const sidebar = document.getElementById("sidebar")
  if (sidebar && sidebar.classList.contains("sidebar-collapsed")) {
    sidebar.classList.remove("sidebar-collapsed")
  }
}

// Initialize on page load
document.addEventListener("DOMContentLoaded", initSidebar)

// Close sidebar on Turbo navigation
document.addEventListener("turbo:load", closeSidebarOnNavigation)
document.addEventListener("turbo:render", closeSidebarOnNavigation)
