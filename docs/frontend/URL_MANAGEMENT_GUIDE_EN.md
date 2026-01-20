# URL Management After Delete (Hotwire / Stimulus)

This guide documents the URL management pattern implemented to prevent `ActiveRecord::RecordNotFound` errors when deleting records via Turbo-powered modals.

---

## 1. Problem Statement

Original flow (before refactor):

1. User sits on index (e.g. `/users`).
2. Clicks Delete → confirmation modal loads inside a Turbo Frame at URL `/users/:id/confirm_delete`.
3. Record is deleted, UI updates, but browser URL stays at `/users/:id/confirm_delete`.
4. User refreshes → Rails tries to load deleted record → `ActiveRecord::RecordNotFound`.

We need to return the URL to the index **without a full page reload** to preserve the SPA feel and avoid errors.

---

## 2. Goals

- Seamless UX: no full redirects for a simple delete.
- Safe refresh: URL always points to a valid page after delete.
- Clear separation of concerns (controller vs view vs JS).
- CSP-friendly (no inline `<script>` or `eval`).
- Reusable across all CRUD modules.

---

## 3. Design Principles (SOLID)

| Principle                      | Application                                                                                                           |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------- |
| Single Responsibility          | Each layer does one thing: controller = business logic, turbo stream = UI orchestration, Stimulus = history mutation. |
| Open/Closed                    | Can add `pushState` or analytics without changing existing structure.                                                 |
| Liskov                         | Works uniformly across all 9 modules (users, roles, etc.).                                                            |
| Interface/Dependency Inversion | Views depend on data attributes & Stimulus API, not ad-hoc scripts.                                                   |
| Security                       | No `eval`, no inline script → CSP compliant.                                                                          |

---

## 4. High-Level Architecture

```
Index Page (has #url-manager placeholder)
   │
Modal (Turbo Frame) → user confirms delete
   │
Controller#destroy (sets flash, responds turbo_stream)
   │
destroy.turbo_stream.erb (4 actions: remove, close modal, flash, url update)
   │
Renders _url_updater.html.erb (Stimulus element)
   │
history_controller.js (connect → replaceState / pushState)
   │
Browser History API (URL back to index)
```

---

## 5. Components

1. **Index Page**: Must include `<div id="url-manager"></div>` below flash container.
2. **Turbo Stream Template**: `destroy.turbo_stream.erb` orchestrates changes.
3. **Shared Partial**: `_url_updater.html.erb` creates a lightweight Stimulus target.
4. **Stimulus Controller**: `history_controller.js` executes `replaceState` / `pushState`.
5. **Modal System**: Existing shared modal pattern unchanged except using consistent stream actions.

---

## 6. Implementation Steps (Per Module)

### A. Index Page Setup

```erb
<div id="flash_messages"><%= render "shared/flash" %></div>
<div id="url-manager"></div>
```

### B. Controller Destroy Action

```ruby
def destroy
  authorize @user
  if @user.destroy
    respond_to do |format|
      format.turbo_stream { flash.now[:notice] = "User deleted successfully." }
      format.html { redirect_to user_management_users_path, notice: "User deleted successfully." }
    end
  else
    redirect_to user_management_users_path, alert: "Failed to delete user."
  end
end
```

### C. Turbo Stream Response

```erb
<%= turbo_stream.remove dom_id(@user) %>
<%= turbo_stream.update "modal", "" %>
<%= turbo_stream.update "flash_messages", partial: "shared/flash" %>
<%= turbo_stream.update "url-manager",
    partial: "shared/url_updater",
    locals: { url: user_management_users_path } %>
```

### D. Shared Partial `_url_updater.html.erb`

```erb
<% method ||= "replaceState" %>
<div data-controller="history"
     data-history-url-value="<%= url %>"
     data-history-method-value="<%= method %>"></div>
```

### E. Stimulus Controller `history_controller.js`

```javascript
export default class extends Controller {
  static values = {
    url: String,
    method: { type: String, default: "replaceState" },
  };
  connect() {
    this.update();
  }
  replace() {
    if (this.hasUrlValue) window.history.replaceState({}, "", this.urlValue);
  }
  push() {
    if (this.hasUrlValue) window.history.pushState({}, "", this.urlValue);
  }
  urlValueChanged() {
    this.methodValue === "pushState" ? this.push() : this.replace();
  }
  update() {
    this.urlValueChanged();
  }
}
```

---

## 7. Execution Flow (Delete Action)

1. User clicks Delete → modal appears inside Turbo Frame.
2. User confirms → form submits DELETE.
3. Controller destroys record, sets `flash.now` and responds `turbo_stream`.
4. Turbo Stream template emits four operations.
5. The last operation injects the URL updater element.
6. Stimulus `connect()` fires → decides replace vs push.
7. Browser URL updated to index path.
8. Page refresh is now safe.

---

## 8. Why Not Inline `<script>`?

| Problem               | Inline Script               | Stimulus                 |
| --------------------- | --------------------------- | ------------------------ |
| Execution reliability | Often skipped when injected | Deterministic on connect |
| CSP compliance        | Usually blocked             | Allowed by design        |
| Security              | Harder to audit             | No eval / inline code    |
| Reuse                 | Copy-paste prone            | Centralized logic        |
| Testability           | Hard                        | Straightforward          |

---

## 9. Extensions / Customization

| Need                         | How                                    |
| ---------------------------- | -------------------------------------- |
| Maintain back button history | Use `method: "pushState"`              |
| Analytics event              | Add call inside `replace()` / `push()` |
| Conditional suppression      | Guard around `this.urlValue`           |

Example with pushState:

```erb
<%= turbo_stream.update "url-manager",
    partial: "shared/url_updater",
    locals: { url: filtered_users_path(params.slice(:role, :page)), method: "pushState" } %>
```

---

## 10. Module Checklist

| Item                                | Required | Verified |
| ----------------------------------- | -------- | -------- |
| Index has `#url-manager`            | Yes      | ✅       |
| destroy.turbo_stream uses 4 actions | Yes      | ✅       |
| `_url_updater` partial exists       | Yes      | ✅       |
| Stimulus controller pinned/imported | Yes      | ✅       |
| No legacy eval file                 | Yes      | ✅       |

---

## 11. Troubleshooting

| Symptom                | Likely Cause               | Fix                                                          |
| ---------------------- | -------------------------- | ------------------------------------------------------------ |
| URL doesn’t change     | Missing `#url-manager` div | Add container to index                                       |
| Flash missing          | Forgot stream update       | Ensure `update "flash_messages"` present                     |
| Modal sticks open      | Missing modal clear        | Ensure `update "modal", ""`                                  |
| Refresh error persists | URL not replaced           | Confirm `_url_updater` rendered                              |
| Stimulus not executing | Controller not loaded      | Check importmap & `import "controllers"` in `application.js` |

---

## 12. Full Example (Users)

`destroy.turbo_stream.erb`

```erb
<%= turbo_stream.remove dom_id(@user) %>
<%= turbo_stream.update "modal", "" %>
<%= turbo_stream.update "flash_messages", partial: "shared/flash" %>
<%= turbo_stream.update "url-manager",
    partial: "shared/url_updater",
    locals: { url: user_management_users_path } %>
```

`_url_updater.html.erb`

```erb
<% method ||= "replaceState" %>
<div data-controller="history"
     data-history-url-value="<%= url %>"
     data-history-method-value="<%= method %>"></div>
```

`history_controller.js`

```javascript
export default class extends Controller {
  static values = {
    url: String,
    method: { type: String, default: "replaceState" },
  };
  connect() {
    this.update();
  }
  replace() {
    if (this.hasUrlValue) window.history.replaceState({}, "", this.urlValue);
  }
  push() {
    if (this.hasUrlValue) window.history.pushState({}, "", this.urlValue);
  }
  urlValueChanged() {
    this.methodValue === "pushState" ? this.push() : this.replace();
  }
  update() {
    this.urlValueChanged();
  }
}
```

Index header snippet:

```erb
<div id="flash_messages"><%= render "shared/flash" %></div>
<div id="url-manager"></div>
```

---

## 13. Benefits Summary

- No redirect required → faster UX.
- Refresh-safe after destructive actions.
- Uniform pattern across all 9 CRUD modules.
- Test-friendly and extensible.
- CSP and security aligned.

---

## 14. Recommended Enhancements (Optional)

- Add system test: delete → assert current_path == index.
- Add analytics hook (e.g. `window.dispatchEvent(new CustomEvent("url:changed"))`).
- Introduce helper wrapper if more metadata is added later.

---

## 15. FAQ

**Q: Why use replaceState for delete?**
Because the intermediate `confirm_delete` URL isn’t a meaningful navigation step; back button should not revisit it.

**Q: Can we force a full redirect instead?**
Yes, but you lose the smoothness and pay extra latency. This pattern is lighter.

**Q: What about query params (filters)?**
Safe—just ensure you pass trusted server-generated URLs (helpers), not raw user input.

---

Last Updated: November 2025
Owner: UI / Hotwire Development Team
