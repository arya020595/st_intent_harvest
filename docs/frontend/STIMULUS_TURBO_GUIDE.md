# ⚡ Stimulus & Hotwired Turbo Guide

## Overview

This guide explains how to use **Stimulus** (modest JavaScript framework) and **Hotwired Turbo** (SPA-like page accelerator) in the ST Intent Harvest application. Together, they provide a modern, reactive user experience without complex JavaScript frameworks.

---

## 📋 Table of Contents

1. [What is Hotwire?](#what-is-hotwire)
2. [Turbo Drive](#turbo-drive)
3. [Turbo Frames](#turbo-frames)
4. [Turbo Streams](#turbo-streams)
5. [Stimulus Controllers](#stimulus-controllers)
6. [Real-World Examples](#real-world-examples)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)

---

## What is Hotwire?

**Hotwire** = HTML Over The Wire

It's an approach to building modern web applications that sends HTML over the wire instead of JSON. The stack consists of:

1. **Turbo Drive** - Accelerates page navigation (replaces Turbolinks)
2. **Turbo Frames** - Decompose pages into independent contexts
3. **Turbo Streams** - Real-time updates via WebSockets or server responses
4. **Stimulus** - Sprinkle JavaScript behavior on HTML

### Current Setup

```javascript
// app/javascript/application.js
import "@hotwired/turbo-rails"  // ✅ Turbo enabled
import "controllers"             // ✅ Stimulus controllers

// config/importmap.rb
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
```

**Benefits:**
- ⚡ Fast page navigation (no full page reload)
- 📦 Small JavaScript footprint
- 🎯 Progressive enhancement
- 🔄 Real-time updates
- 🚀 SPA-like feel with server-rendered HTML

---

## Turbo Drive

**Turbo Drive** automatically intercepts link clicks and form submissions, making them faster by replacing only the `<body>` while keeping the `<head>`.

### How It Works

```
Without Turbo:
Click Link → Full Page Reload → Parse CSS/JS → Render → Flash of Blank Page

With Turbo Drive:
Click Link → Fetch HTML (XHR) → Replace <body> → Smooth Transition
```

### Usage (Automatic!)

Turbo Drive works automatically. Just write normal Rails links and forms:

```erb
<!-- Normal link - Turbo intercepts automatically -->
<%= link_to 'Products', products_path %>

<!-- Normal form - Turbo intercepts automatically -->
<%= form_with model: @product do |f| %>
  <%= f.text_field :name %>
  <%= f.submit %>
<% end %>
```

### Opt-Out When Needed

```erb
<!-- Disable Turbo for specific link (e.g., file download) -->
<%= link_to 'Download PDF', report_path, data: { turbo: false } %>

<!-- Disable Turbo for entire form -->
<%= form_with model: @product, data: { turbo: false } do |f| %>
  ...
<% end %>
```

### Progress Bar

Turbo shows a progress bar during navigation. Customize it:

```css
/* app/assets/stylesheets/application.css */
.turbo-progress-bar {
  height: 5px;
  background-color: #0d6efd; /* Bootstrap primary blue */
}
```

---

## Turbo Frames

**Turbo Frames** allow you to update parts of a page independently without full page reload.

### Concept

```
┌─────────────────────────────────────┐
│           Page Layout               │
│  ┌───────────────────────────────┐  │
│  │  Navigation (static)          │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │  <turbo-frame id="content">   │  │ ← Only this updates!
│  │    Dynamic content here       │  │
│  │  </turbo-frame>               │  │
│  └───────────────────────────────┘  │
│  ┌───────────────────────────────┐  │
│  │  Footer (static)              │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

### Example 1: Inline Editing

**Index Page:**
```erb
<%# app/views/products/index.html.erb %>

<h1>Products</h1>

<% @products.each do |product| %>
  <%= turbo_frame_tag "product_#{product.id}" do %>
    <div class="card mb-3">
      <div class="card-body">
        <h3><%= product.name %></h3>
        <p><%= product.description %></p>
        <p>Price: <%= number_to_currency(product.unit_price) %></p>
        
        <%= link_to 'Edit', edit_product_path(product), class: 'btn btn-warning' %>
      </div>
    </div>
  <% end %>
<% end %>
```

**Edit Form (Replaces Frame):**
```erb
<%# app/views/products/edit.html.erb %>

<%= turbo_frame_tag "product_#{@product.id}" do %>
  <div class="card mb-3">
    <div class="card-body">
      <%= form_with model: @product do |f| %>
        <%= f.text_field :name, class: 'form-control mb-2' %>
        <%= f.text_area :description, class: 'form-control mb-2' %>
        <%= f.number_field :unit_price, class: 'form-control mb-2' %>
        
        <%= f.submit 'Save', class: 'btn btn-primary' %>
        <%= link_to 'Cancel', product_path(@product), class: 'btn btn-secondary' %>
      <% end %>
    </div>
  </div>
<% end %>
```

**Controller:**
```ruby
# app/controllers/products_controller.rb
def update
  @product = Product.find(params[:id])
  
  if @product.update(product_params)
    # Turbo replaces the frame with the show view
    redirect_to @product, notice: 'Updated!'
  else
    # Re-render edit form in the frame
    render :edit, status: :unprocessable_entity
  end
end
```

**What Happens:**
1. Click "Edit" → Turbo loads edit form into `turbo_frame_tag "product_#{product.id}"`
2. Submit form → Turbo updates only that frame
3. No full page reload! ⚡

### Example 2: Modal with Turbo Frame

**Index with Modal Trigger:**
```erb
<%# app/views/products/index.html.erb %>

<%= link_to 'New Product', new_product_path, 
    data: { turbo_frame: 'modal' }, 
    class: 'btn btn-primary' %>

<!-- Modal container -->
<%= turbo_frame_tag 'modal' %>
```

**Modal View:**
```erb
<%# app/views/products/new.html.erb %>

<%= turbo_frame_tag 'modal' do %>
  <div class="modal show d-block" tabindex="-1">
    <div class="modal-dialog">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title">New Product</h5>
          <%= link_to '×', products_path, class: 'btn-close' %>
        </div>
        <div class="modal-body">
          <%= form_with model: @product do |f| %>
            <%= f.text_field :name, class: 'form-control mb-2' %>
            <%= f.submit 'Create', class: 'btn btn-primary' %>
          <% end %>
        </div>
      </div>
    </div>
  </div>
<% end %>
```

### Breaking Out of Frames

```erb
<!-- Link navigates the whole page, not just the frame -->
<%= link_to 'View All', products_path, data: { turbo_frame: '_top' } %>
```

---

## Turbo Streams

**Turbo Streams** allow you to update **multiple parts** of a page from a single server response.

### Seven Actions

1. **append** - Add content to end of target
2. **prepend** - Add content to beginning of target
3. **replace** - Replace entire target element
4. **update** - Replace content inside target
5. **remove** - Delete target element
6. **before** - Insert before target
7. **after** - Insert after target

### Example 1: Append New Product (CRUD Create)

**Controller:**
```ruby
# app/controllers/products_controller.rb
def create
  @product = Product.new(product_params)
  
  respond_to do |format|
    if @product.save
      format.turbo_stream # Renders create.turbo_stream.erb
      format.html { redirect_to @product }
    else
      format.html { render :new, status: :unprocessable_entity }
    end
  end
end
```

**Turbo Stream Template:**
```erb
<%# app/views/products/create.turbo_stream.erb %>

<%# 1. Append new product to list %>
<%= turbo_stream.append 'products' do %>
  <%= render partial: 'product', locals: { product: @product } %>
<% end %>

<%# 2. Clear form %>
<%= turbo_stream.update 'new_product_form' do %>
  <%= form_with model: Product.new, id: 'new_product_form' do |f| %>
    <%= f.text_field :name, value: '', class: 'form-control' %>
    <%= f.submit 'Add Product' %>
  <% end %>
<% end %>

<%# 3. Show success message %>
<%= turbo_stream.prepend 'flash_messages' do %>
  <div class="alert alert-success">Product created!</div>
<% end %>
```

**View:**
```erb
<%# app/views/products/index.html.erb %>

<div id="flash_messages"></div>

<h1>Products</h1>

<%= form_with model: Product.new, id: 'new_product_form' do |f| %>
  <%= f.text_field :name, class: 'form-control' %>
  <%= f.submit 'Add Product', class: 'btn btn-primary' %>
<% end %>

<div id="products">
  <%= render @products %>
</div>
```

### Example 2: Remove Product (CRUD Destroy)

**Controller:**
```ruby
def destroy
  @product = Product.find(params[:id])
  @product.destroy
  
  respond_to do |format|
    format.turbo_stream # Renders destroy.turbo_stream.erb
    format.html { redirect_to products_path }
  end
end
```

**Turbo Stream Template:**
```erb
<%# app/views/products/destroy.turbo_stream.erb %>

<%= turbo_stream.remove "product_#{@product.id}" %>

<%= turbo_stream.prepend 'flash_messages' do %>
  <div class="alert alert-info">Product deleted!</div>
<% end %>
```

### Example 3: Real-Time Updates (WebSocket)

**Model Broadcast:**
```ruby
# app/models/product.rb
class Product < ApplicationRecord
  after_create_commit -> { broadcast_prepend_to 'products' }
  after_update_commit -> { broadcast_replace_to 'products' }
  after_destroy_commit -> { broadcast_remove_to 'products' }
end
```

**View:**
```erb
<%# app/views/products/index.html.erb %>

<%# Subscribe to Turbo Stream broadcasts %>
<%= turbo_stream_from 'products' %>

<div id="products">
  <%= render @products %>
</div>
```

**What Happens:**
- Any user creates a product → All connected users see it appear instantly! 🚀
- Uses Action Cable (WebSocket) under the hood

---

## Stimulus Controllers

**Stimulus** adds JavaScript behavior to HTML elements using controllers, targets, and actions.

### Architecture

```
HTML Element (data-controller="hello")
     ↓
Stimulus Controller (hello_controller.js)
     ↓
Actions (methods that respond to events)
     ↓
Targets (references to HTML elements)
     ↓
Values (reactive data attributes)
```

### Anatomy of a Stimulus Controller

```javascript
// app/javascript/controllers/hello_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // 1. Define targets (HTML elements this controller manages)
  static targets = ["name", "output"]
  
  // 2. Define values (reactive data)
  static values = {
    greeting: String,
    count: { type: Number, default: 0 }
  }
  
  // 3. Lifecycle callbacks
  connect() {
    console.log("Hello controller connected!")
    // Runs when controller connects to DOM
  }
  
  disconnect() {
    // Runs when controller disconnects from DOM
  }
  
  // 4. Actions (methods triggered by events)
  greet() {
    const name = this.nameTarget.value
    this.outputTarget.textContent = `${this.greetingValue} ${name}!`
    this.countValue++
  }
  
  // 5. Value changed callbacks
  countValueChanged() {
    console.log(`Count is now: ${this.countValue}`)
  }
}
```

### Using the Controller in HTML

```erb
<div data-controller="hello"
     data-hello-greeting-value="Hello">
  
  <!-- Target: name -->
  <input type="text" 
         data-hello-target="name"
         placeholder="Your name">
  
  <!-- Action: greet on click -->
  <button data-action="click->hello#greet">
    Say Hello
  </button>
  
  <!-- Target: output -->
  <div data-hello-target="output"></div>
</div>
```

### Naming Convention

```
File: hello_controller.js       → data-controller="hello"
File: product_form_controller.js → data-controller="product-form"
File: user_dropdown_controller.js → data-controller="user-dropdown"
```

**Rule:** CamelCase in JS → kebab-case in HTML

---

## Real-World Examples

### Example 1: Auto-Save Form

**Controller:**
```javascript
// app/javascript/controllers/autosave_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status"]
  static values = {
    url: String,
    delay: { type: Number, default: 1000 }
  }
  
  connect() {
    this.timeout = null
  }
  
  // Debounced save
  save() {
    clearTimeout(this.timeout)
    
    this.timeout = setTimeout(() => {
      this.submitForm()
    }, this.delayValue)
  }
  
  async submitForm() {
    this.statusTarget.textContent = "Saving..."
    
    const formData = new FormData(this.element)
    
    try {
      const response = await fetch(this.urlValue, {
        method: 'PATCH',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      })
      
      if (response.ok) {
        this.statusTarget.textContent = "✓ Saved"
        setTimeout(() => {
          this.statusTarget.textContent = ""
        }, 2000)
      } else {
        this.statusTarget.textContent = "✗ Error"
      }
    } catch (error) {
      console.error('Save failed:', error)
      this.statusTarget.textContent = "✗ Error"
    }
  }
}
```

**HTML:**
```erb
<%= form_with model: @product,
    data: { 
      controller: 'autosave',
      autosave_url_value: product_path(@product),
      action: 'input->autosave#save'
    } do |f| %>
  
  <%= f.text_field :name, class: 'form-control' %>
  <%= f.text_area :description, class: 'form-control' %>
  
  <span data-autosave-target="status" class="text-muted"></span>
<% end %>
```

### Example 2: Confirmation Dialog

**Controller:**
```javascript
// app/javascript/controllers/confirm_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    message: { type: String, default: "Are you sure?" }
  }
  
  confirm(event) {
    if (!window.confirm(this.messageValue)) {
      event.preventDefault()
      event.stopImmediatePropagation()
    }
  }
}
```

**HTML:**
```erb
<%= link_to 'Delete Product', 
    product_path(@product),
    data: { 
      turbo_method: :delete,
      controller: 'confirm',
      action: 'click->confirm#confirm',
      confirm_message_value: 'Delete this product? This cannot be undone.'
    },
    class: 'btn btn-danger' %>
```

### Example 3: Dynamic Form Fields

**Controller:**
```javascript
// app/javascript/controllers/nested_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "container"]
  
  add(event) {
    event.preventDefault()
    
    // Get template content
    const content = this.templateTarget.innerHTML
    
    // Replace timestamp to make fields unique
    const timestamp = new Date().getTime()
    const uniqueContent = content.replace(/NEW_RECORD/g, timestamp)
    
    // Append to container
    this.containerTarget.insertAdjacentHTML('beforeend', uniqueContent)
  }
  
  remove(event) {
    event.preventDefault()
    
    const wrapper = event.target.closest('.nested-fields')
    
    // If persisted record, mark for destruction
    if (wrapper.dataset.newRecord === "false") {
      wrapper.querySelector("input[name*='_destroy']").value = "1"
      wrapper.style.display = 'none'
    } else {
      // Otherwise just remove from DOM
      wrapper.remove()
    }
  }
}
```

**HTML:**
```erb
<div data-controller="nested-form">
  <h3>Product Variants</h3>
  
  <div data-nested-form-target="container">
    <%= f.fields_for :variants do |variant_form| %>
      <div class="nested-fields" data-new-record="false">
        <%= variant_form.text_field :name %>
        <%= variant_form.hidden_field :_destroy %>
        <button data-action="click->nested-form#remove">Remove</button>
      </div>
    <% end %>
  </div>
  
  <button data-action="click->nested-form#add">Add Variant</button>
  
  <!-- Template for new fields -->
  <template data-nested-form-target="template">
    <div class="nested-fields" data-new-record="true">
      <input type="text" name="product[variants_attributes][NEW_RECORD][name]">
      <button data-action="click->nested-form#remove">Remove</button>
    </div>
  </template>
</div>
```

### Example 4: Dropdown Toggle

**Controller:**
```javascript
// app/javascript/controllers/dropdown_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]
  static classes = ["open"]
  
  connect() {
    // Close dropdown when clicking outside
    this.boundClose = this.close.bind(this)
  }
  
  toggle(event) {
    event.stopPropagation()
    this.menuTarget.classList.toggle(this.openClass)
    
    if (this.menuTarget.classList.contains(this.openClass)) {
      document.addEventListener('click', this.boundClose)
    }
  }
  
  close() {
    this.menuTarget.classList.remove(this.openClass)
    document.removeEventListener('click', this.boundClose)
  }
  
  disconnect() {
    document.removeEventListener('click', this.boundClose)
  }
}
```

**HTML:**
```erb
<div data-controller="dropdown"
     data-dropdown-open-class="show">
  
  <button data-action="click->dropdown#toggle">
    Actions ▼
  </button>
  
  <div data-dropdown-target="menu" class="dropdown-menu">
    <%= link_to 'Edit', edit_product_path(@product) %>
    <%= link_to 'Delete', product_path(@product), data: { turbo_method: :delete } %>
  </div>
</div>
```

**CSS:**
```css
.dropdown-menu {
  display: none;
}

.dropdown-menu.show {
  display: block;
}
```

### Example 5: Search with Debounce

**Controller:**
```javascript
// app/javascript/controllers/search_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results"]
  static values = {
    url: String,
    delay: { type: Number, default: 300 }
  }
  
  connect() {
    this.timeout = null
  }
  
  search() {
    clearTimeout(this.timeout)
    
    this.timeout = setTimeout(() => {
      this.performSearch()
    }, this.delayValue)
  }
  
  async performSearch() {
    const query = this.inputTarget.value
    
    if (query.length < 2) {
      this.resultsTarget.innerHTML = ''
      return
    }
    
    try {
      const response = await fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`, {
        headers: {
          'Accept': 'text/html',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      const html = await response.text()
      this.resultsTarget.innerHTML = html
    } catch (error) {
      console.error('Search failed:', error)
    }
  }
}
```

**HTML:**
```erb
<div data-controller="search"
     data-search-url-value="<%= search_products_path %>">
  
  <input type="text"
         data-search-target="input"
         data-action="input->search#search"
         placeholder="Search products..."
         class="form-control">
  
  <div data-search-target="results"></div>
</div>
```

**Controller (Rails):**
```ruby
# app/controllers/products_controller.rb
def search
  @products = Product.where("name ILIKE ?", "%#{params[:q]}%").limit(10)
  
  render partial: 'search_results', locals: { products: @products }
end
```

---

## Best Practices

### 1. Progressive Enhancement

Always make features work without JavaScript first:

```erb
<!-- Works without JS (full page reload) -->
<%= link_to 'Products', products_path %>

<!-- Enhanced with Turbo (AJAX navigation) -->
<!-- No code change needed! Turbo intercepts automatically -->
```

### 2. Keep Controllers Small and Focused

```javascript
// ❌ Bad: One controller doing everything
export default class extends Controller {
  validateForm() { }
  submitForm() { }
  toggleDropdown() { }
  sortTable() { }
  // ... 20 more methods
}

// ✅ Good: Separate controllers
// form_validation_controller.js
// form_submit_controller.js
// dropdown_controller.js
// table_sort_controller.js
```

### 3. Use Data Attributes for Configuration

```erb
<!-- ❌ Bad: Hardcoded in JavaScript -->
<div data-controller="timer"></div>

<!-- ✅ Good: Configurable via HTML -->
<div data-controller="timer"
     data-timer-interval-value="5000"
     data-timer-autostart-value="true">
</div>
```

### 4. Clean Up in disconnect()

```javascript
export default class extends Controller {
  connect() {
    this.interval = setInterval(() => {
      this.refresh()
    }, 1000)
  }
  
  disconnect() {
    // ✅ Always clean up timers, listeners, etc.
    clearInterval(this.interval)
  }
}
```

### 5. Turbo Frame Best Practices

```erb
<!-- ✅ Good: Lazy loading -->
<%= turbo_frame_tag 'comments', src: product_comments_path(@product), loading: :lazy do %>
  Loading comments...
<% end %>

<!-- ✅ Good: Descriptive IDs -->
<%= turbo_frame_tag "product_#{@product.id}_details" do %>
  ...
<% end %>

<!-- ❌ Bad: Generic IDs that might conflict -->
<%= turbo_frame_tag "details" do %>
  ...
<% end %>
```

### 6. Handle Errors Gracefully

```ruby
# app/controllers/products_controller.rb
def create
  @product = Product.new(product_params)
  
  respond_to do |format|
    if @product.save
      format.turbo_stream
      format.html { redirect_to @product }
    else
      format.turbo_stream {
        render turbo_stream: turbo_stream.replace(
          'product_form',
          partial: 'form',
          locals: { product: @product }
        ), status: :unprocessable_entity
      }
      format.html { render :new, status: :unprocessable_entity }
    end
  end
end
```

---

## Troubleshooting

### Problem 1: Turbo Frame Not Updating

**Symptoms:**
- Click link, nothing happens
- Console error: "Content missing"

**Solution:**
Ensure matching `turbo_frame_tag` IDs:

```erb
<!-- List page -->
<%= turbo_frame_tag "product_#{@product.id}" do %>
  <%= link_to 'Edit', edit_product_path(@product) %>
<% end %>

<!-- Edit page - MUST have same ID! -->
<%= turbo_frame_tag "product_#{@product.id}" do %>
  <%= form_with model: @product do |f| %>
    ...
  <% end %>
<% end %>
```

### Problem 2: Form Redirects Don't Work

**Symptoms:**
- After form submit, redirect is ignored
- Stuck on same page

**Solution:**
Either break out of frame or use Turbo Stream:

```ruby
# Option 1: Break out of frame
redirect_to @product, status: :see_other

# Option 2: Use Turbo Stream
respond_to do |format|
  format.turbo_stream
  format.html { redirect_to @product }
end
```

### Problem 3: Stimulus Controller Not Connecting

**Symptoms:**
- Controller's `connect()` never runs
- No console logs

**Checklist:**
```javascript
// ✅ 1. Filename matches: hello_controller.js
// ✅ 2. Exports default class
export default class extends Controller {
  connect() {
    console.log("Connected!")
  }
}

// ✅ 3. HTML uses correct name
<div data-controller="hello">
```

### Problem 4: CSRF Token Missing

**Symptoms:**
- 422 Unprocessable Entity on AJAX requests

**Solution:**
```javascript
fetch(url, {
  method: 'POST',
  headers: {
    'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify(data)
})
```

### Problem 5: Turbo Cache Shows Stale Data

**Symptoms:**
- After logout, cached pages still show user data

**Solution:**
```erb
<!-- Disable caching for this page -->
<meta name="turbo-cache-control" content="no-cache">

<!-- Or in controller -->
<% response.headers['Turbo-Visit-Control'] = 'reload' %>
```

---

## Quick Reference

### Turbo Frame Syntax

```erb
<%= turbo_frame_tag 'unique_id' do %>
  Content here
<% end %>

<%= turbo_frame_tag 'lazy_frame', src: path_to_load, loading: :lazy %>

<%= link_to 'Text', path, data: { turbo_frame: 'target_id' } %>

<%= link_to 'Text', path, data: { turbo_frame: '_top' } %>  <!-- Break out -->
```

### Turbo Stream Actions

```erb
<%= turbo_stream.append 'id', html %>
<%= turbo_stream.prepend 'id', html %>
<%= turbo_stream.replace 'id', html %>
<%= turbo_stream.update 'id', html %>
<%= turbo_stream.remove 'id' %>
<%= turbo_stream.before 'id', html %>
<%= turbo_stream.after 'id', html %>
```

### Stimulus Data Attributes

```erb
data-controller="name"
data-name-target="targetName"
data-action="event->name#method"
data-name-value-name-value="value"
data-name-class-name-class="css-class"
```

### Common Stimulus Patterns

```javascript
// Targets
static targets = ["element"]
this.elementTarget
this.elementTargets  // Array
this.hasElementTarget

// Values
static values = { name: String, count: Number, enabled: Boolean }
this.nameValue
this.nameValue = "new"
nameValueChanged() { }

// Classes
static classes = ["active", "hidden"]
this.activeClass
this.element.classList.add(this.activeClass)

// Lifecycle
connect() { }
disconnect() { }
targetConnected(element, name) { }
targetDisconnected(element, name) { }
```

---

## Summary

**Hotwire Stack:**
- 🚀 **Turbo Drive** - Automatic page acceleration
- 🎯 **Turbo Frames** - Update page sections independently
- 🔄 **Turbo Streams** - Multiple updates from one response
- ⚡ **Stimulus** - Sprinkle JavaScript on HTML

**When to Use What:**

| Need | Use |
|------|-----|
| Fast navigation | Turbo Drive (automatic!) |
| Update one section | Turbo Frames |
| Update multiple sections | Turbo Streams |
| Add interactivity | Stimulus |
| Real-time updates | Turbo Streams + Action Cable |

**Development Workflow:**
1. Build feature with standard Rails (forms, links)
2. Turbo Drive makes it faster (automatic)
3. Add Turbo Frames for specific sections
4. Add Turbo Streams for complex updates
5. Add Stimulus for client-side interactivity

🎉 **You now have a modern, reactive app without heavy JavaScript frameworks!**
