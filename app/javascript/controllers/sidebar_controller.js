import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.setupToggle()
    this.setupTurboListeners()
  }

  setupToggle() {
    // Use event delegation on document to avoid null references
    document.addEventListener("click", (event) => {
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
      
      this.closeSidebar()
    })
  }

  setupTurboListeners() {
    // Close sidebar on Turbo navigation (handles Turbo Drive page changes)
    document.addEventListener("turbo:load", () => this.closeSidebar())
    document.addEventListener("turbo:render", () => this.closeSidebar())
  }

  closeSidebar() {
    const sidebar = document.getElementById("sidebar")
    if (sidebar && sidebar.classList.contains("sidebar-collapsed")) {
      sidebar.classList.remove("sidebar-collapsed")
    }
  }
}
