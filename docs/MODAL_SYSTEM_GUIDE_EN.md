# Modal System Guide (Shared Component + Stimulus + Turbo Frames)

This guide explains the refactored modal architecture: goals, structure, usage patterns, logic flow, extensibility, and best practices.

---

## 1. Goals

| Goal                  | Outcome                                                         |
| --------------------- | --------------------------------------------------------------- |
| DRY across modules    | Single shared partial `shared/_modal.html.erb`                  |
| Dynamic sizing        | Link-level data attribute (`data-modal-size`) sets dialog width |
| Fast & incremental    | Turbo Frame loads only inner content, container persists        |
| Accessible            | Adds `role="dialog"` + `aria-modal="true"`, label linkage       |
| Predictable lifecycle | Stimulus controller manages show/hide, cleanup, focus           |
| Safe fallback         | Form submissions degrade to full HTML when not Turbo            |

---

## 2. High-Level Architecture

```
Index / Page Layout
  └── Renders module-specific _modal partial (delegates to shared/_modal)
         └── shared/_modal.html.erb (static container + Turbo Frame)
                └── Turbo Frame loads dynamic view (form, confirm, etc.)
                       └── Stimulus modal_controller.js handles size, focus, cleanup
```

---

## 3. Core Files

| File                                                    | Purpose                                                 |
| ------------------------------------------------------- | ------------------------------------------------------- |
| `app/views/shared/_modal.html.erb`                      | Structural container & Turbo Frame wrapper              |
| `app/helpers/modal_helper.rb`                           | `modal_link_data` & `modal_config` helpers              |
| `app/javascript/controllers/modal_controller.js`        | Lifecycle, dynamic size, focus, cleanup                 |
| `module/_modal.html.erb` (e.g. `users/_modal.html.erb`) | Thin wrapper calling shared partial                     |
| `shared/_confirm_delete.html.erb`                       | Standard delete confirmation content inside modal frame |

---

## 4. Shared Modal Partial (`shared/_modal.html.erb`)

Responsibilities:

- Render a **persistent container** that Bootstrap can attach to.
- Contain a Turbo Frame for swapping inner content.
- Provide hooks (data attributes) for Stimulus.

Key attributes added:

```erb
<div class="modal fade"
     id="userModal"
     role="dialog" aria-modal="true"
     aria-labelledby="userModalLabel"
     data-controller="modal"
     data-modal-frame-id-value="modal">
  ...
</div>
```

Why persistent? Only the inner content swaps; avoids re-initializing Bootstrap and losing focus transitions.

---

## 5. Helpers (`modal_helper.rb`)

### `modal_link_data(size: 'modal-lg')`

Generates correct attributes for trigger links:

```ruby
link_to "Edit", edit_user_path(user), **modal_link_data(size: "modal-xl")
```

Outputs:

```html
<a data-turbo-frame="modal" data-modal-size="modal-xl">Edit</a>
```

### `modal_config(id: ..., default_size: ...)`

Used by module `_modal` wrappers:

```erb
<%= render "shared/modal", **modal_config(id: "userModal", default_size: "modal-lg") %>
```

Extensible: add new modal options (e.g. scrollable) by expanding the hash and partial logic.

---

## 6. Stimulus Controller (`modal_controller.js`)

Responsibilities:
| Concern | Behavior |
|---------|----------|
| Show event | Listens for `turbo:frame-load` → calls `show()` |
| Dynamic size | Reads `window.lastModalTrigger.dataset.modalSize` |
| Focus | On `shown.bs.modal` focuses first interactive field |
| Cleanup | On hide, clears Turbo Frame inner HTML to avoid stale state |
| Submission | On `turbo:submit-end` hides modal when success (200/201); stays open on validation failure |
| History Safety | Modal content is not cached thanks to `turbo:before-cache` hide call |

Dynamic sizing logic snippet:

```javascript
applyDynamicSize() {
  const modalDialog = this.element.querySelector(".modal-dialog")
  // Remove previous size classes
  this.constructor.VALID_SIZES.forEach(size => modalDialog.classList.remove(size))
  const trigger = window.lastModalTrigger
  if (trigger?.dataset?.modalSize && this.constructor.VALID_SIZES.includes(trigger.dataset.modalSize)) {
    modalDialog.classList.add(trigger.dataset.modalSize)
  }
}
```

Global capture of last clicked trigger is set in `controllers/application.js`:

```javascript
document.addEventListener("click", (e) => {
  const link = e.target.closest("a[data-turbo-frame='modal']");
  if (link) window.lastModalTrigger = link;
});
```

---

## 7. Usage Patterns

### A. Include Modal Container Once Per Page

```erb
<%= render "user_management/users/modal" %>
```

Do this near the bottom of index/show views so it’s available globally.

### B. Trigger Links

```erb
<%= link_to "New User", new_user_management_user_path, **modal_link_data(size: "modal-lg") %>
<%= link_to "Delete", confirm_delete_user_management_user_path(user), **modal_link_data(size: "modal-md") %>
```

### C. Forms Within Modals

Ensure forms submit to `_top` frame when you want a full stream response:

```erb
<%= form_with model: @user, data: { turbo_frame: "_top" } do |f| %>
  ...
<% end %>
```

### D. Delete Confirmation

Reuses `shared/_confirm_delete.html.erb` inside the same modal frame.

### E. Changing Size Per Action

Just change `size:` option in `modal_link_data`. Default size falls back to `modal-lg` if invalid.

---

## 8. Lifecycle Diagram

```
Click trigger (link with data-turbo-frame="modal")
   │
Turbo loads target URL into frame
   │
Frame load event → Stimulus modal#show
   │
Size applied → Bootstrap .show()
   │
User interacts (submit)
   │
On success: turbo:submit-end → hide modal → clear frame
On failure: modal stays open with validation errors
```

---

## 9. Accessibility Notes

- Added `role="dialog"` and `aria-modal="true"` on container.
- `aria-labelledby` points to a generated label ID: `#{modal_id}Label`.
- Focus is auto-directed to first interactive element improving keyboard navigation.
- ESC key behavior is off by default (`keyboard: false`) to enforce explicit dismissal; can enable with `modal_config(..., keyboard: true)`.

Potential future enhancements:
| Feature | Benefit |
|---------|--------|
| Trap focus | Prevent tabbing behind dialog |
| Announce dynamic content changes | Improved screen reader experience |
| Add `aria-describedby` | Richer semantic context |

---

## 10. Extensibility Examples

| Need                  | How                                                              |
| --------------------- | ---------------------------------------------------------------- |
| Scrollable modal      | Add class `modal-dialog-scrollable` via config and partial logic |
| Fullscreen variant    | Already supported by `modal-fullscreen` size                     |
| Additional animation  | Add custom class & CSS, toggle in Stimulus before show           |
| Auto-close on timeout | Add a `data-auto-close-ms` and handle in controller connect      |

Add new size:

```ruby
# modal_helper.rb
MODAL_SIZES = %w[modal-sm modal-md modal-lg modal-xl modal-fullscreen modal-xxl].freeze
```

---

## 11. Common Pitfalls & Fixes

| Problem                       | Cause                                              | Fix                                                                 |
| ----------------------------- | -------------------------------------------------- | ------------------------------------------------------------------- |
| Modal flickers                | Container re-rendered instead of frame             | Ensure only frame content loads, container static                   |
| Size not applied              | Missing global click capture                       | Confirm `controllers/application.js` sets `window.lastModalTrigger` |
| Validation errors not visible | Form submitted inside frame without errors partial | Render errors inside form partial (still within frame)              |
| Modal stays with old data     | Clear not triggered                                | Ensure `hidden.bs.modal` event attached (already handled)           |

---

## 12. Testing Recommendations

System Test (pseudo):

```ruby
visit users_path
click_link "New User"
within "#userModal" do
  fill_in "Name", with: "Test User"
  click_button "Create User"
end
assert_text "User created successfully"
refute_selector "#userModal .modal-content" # Frame cleared
```

Stimulus Unit Test (optional):

```javascript
// Pseudo using Jest + testing-library
modalController.applyDynamicSize();
expect(dialog.classList.contains("modal-xl")).toBe(true);
```

---

## 13. Why Not Rebuild Container Each Time?

| Approach                           | Drawbacks                                                                             |
| ---------------------------------- | ------------------------------------------------------------------------------------- |
| Full HTML re-render of modal       | Loses animation continuity, flickers, rebinds event listeners, harder to manage state |
| Shared container + frame (current) | Stable, minimal DOM churn, easier debugging                                           |

---

## 14. Integration With URL Management

Destroy flows close modal then update URL via separate history controller. Separation ensures modal system stays focused purely on display & interaction.

---

## 15. Maintenance Checklist

| Item                | Interval  | Action                                    |
| ------------------- | --------- | ----------------------------------------- |
| Sizes list current  | Quarterly | Remove unused / add needed                |
| Accessibility audit | Quarterly | Verify labels & focus behavior            |
| Stimulus warnings   | Ongoing   | Investigate console.warn usage            |
| Dead partials       | Ongoing   | Delete unused \*\_modal.html.erb wrappers |

---

## 16. Summary

The modal system:

- Centralizes structure in one shared partial.
- Configurable via lightweight helpers.
- Keeps logic decoupled (Stimulus for lifecycle, Ruby for config).
- Supports dynamic sizing, safe cleanup, accessibility baseline.
- Plays well with Turbo Streams & history management patterns.

Ready for production and easy evolution.

---

Last Updated: November 2025
Owner: UI/Hotwire Development Team
