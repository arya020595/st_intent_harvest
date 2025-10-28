# 🚀 Rails Development Workflow Guide

## Overview

This guide provides a step-by-step workflow for developing new features in the ST Intent Harvest application. Follow these steps to ensure consistency, quality, and adherence to our team's best practices.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Development Workflow Overview](#development-workflow-overview)
3. [Step-by-Step Feature Development](#step-by-step-feature-development)
4. [Detailed Steps](#detailed-steps)
5. [Testing Guidelines](#testing-guidelines)
6. [Code Review Checklist](#code-review-checklist)
7. [Common Patterns](#common-patterns)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)

---

## Prerequisites

Before starting development, ensure you have:

- ✅ Docker and Docker Compose installed
- ✅ Git configured with your credentials
- ✅ Access to the repository
- ✅ Development environment running (`docker compose up`)
- ✅ Read the following documentation:
  - [Quick Start Guide](QUICK_START.md)
  - [Docker Setup](DOCKER_COMPOSE_EXPLAINED.md)
  - [Git Branching Strategy](GIT_BRANCHING_STRATEGY.md)
  - [Pundit Authorization](PUNDIT_AUTHORIZATION.md)

---

## Development Workflow Overview

```
┌─────────────────────────────────────────────────────────────┐
│           RAILS FEATURE DEVELOPMENT WORKFLOW                │
└─────────────────────────────────────────────────────────────┘

1️⃣  Create Feature Branch
    git checkout -b feature/123-add-inventory
    
2️⃣  Database Layer
    ├── Create Migration
    ├── Generate Model
    ├── Run Migration
    └── Add Seeds (optional)
    
3️⃣  Business Logic Layer
    ├── Create Policy (Pundit)
    ├── Create Service (if complex logic)
    └── Add Model Validations/Associations
    
4️⃣  Routes & Controller
    ├── Add Routes
    ├── Generate Controller
    └── Implement Controller Actions
    
5️⃣  Views Layer
    ├── Create View Templates
    ├── Add Forms
    └── Style with CSS/Bootstrap
    
6️⃣  Testing
    ├── Write Model Tests
    ├── Write Controller Tests
    ├── Manual Testing
    └── Fix Bugs
    
7️⃣  Code Quality
    ├── Run RuboCop
    ├── Run Tests
    └── Update Documentation
    
8️⃣  Submit for Review
    ├── Push to Remote
    ├── Create Pull Request
    └── Address Review Comments
    
9️⃣  Merge & Deploy
    ├── Merge to Develop
    └── Test on Staging
```

---

## Step-by-Step Feature Development

### Example Feature: Adding Product Management

Let's build a complete feature for managing products in our inventory system.

**Requirements:**
- CRUD operations for products
- Only Superadmin and Manager can create/update/delete
- All authenticated users can view
- Track changes with Audited

---

## Detailed Steps

### Step 1: Create Feature Branch

```bash
# Update develop branch
git checkout develop
git pull origin develop

# Create feature branch (follow naming convention)
git checkout -b feature/123-add-product-management

# Verify you're on the correct branch
git branch
```

**Naming Convention:** `feature/<issue-number>-<short-description>`

---

### Step 2: Plan Your Database Schema

Before coding, plan your database structure:

```
products table:
├── id (primary key)
├── name (string, required)
├── sku (string, unique, required)
├── description (text, optional)
├── unit_price (decimal, required)
├── stock_quantity (integer, default: 0)
├── category_id (foreign key → categories)
├── is_active (boolean, default: true)
├── timestamps (created_at, updated_at)
```

---

### Step 3: Create Migration

```bash
# Generate migration
docker compose exec web rails generate migration CreateProducts \
  name:string \
  sku:string:uniq \
  description:text \
  unit_price:decimal \
  stock_quantity:integer \
  category_id:references \
  is_active:boolean

# This creates: db/migrate/XXXXXX_create_products.rb
```

**Edit the migration file:**

```ruby
# db/migrate/20251028000000_create_products.rb
class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.string :sku, null: false
      t.text :description
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.integer :stock_quantity, default: 0
      t.references :category, null: false, foreign_key: true
      t.boolean :is_active, default: true

      t.timestamps
    end

    add_index :products, :sku, unique: true
    add_index :products, :is_active
  end
end
```

**Why these details?**
- `null: false` → Required fields
- `precision: 10, scale: 2` → Money values (10 digits, 2 decimals)
- `default: 0` → Default values
- `add_index` → Better query performance

---

### Step 4: Generate Model

```bash
# Generate model
docker compose exec web rails generate model Product \
  --skip-migration

# This creates: app/models/product.rb
```

**Edit the model:**

```ruby
# app/models/product.rb
class Product < ApplicationRecord
  # Auditing (track all changes)
  audited
  
  # Associations
  belongs_to :category
  has_many :inventory_transactions, dependent: :restrict_with_error
  
  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :sku, presence: true, uniqueness: { case_sensitive: false }
  validates :unit_price, presence: true, numericality: { greater_than: 0 }
  validates :stock_quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  
  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :by_category, ->(category_id) { where(category_id: category_id) }
  scope :low_stock, -> { where('stock_quantity < ?', 10) }
  
  # Instance Methods
  def low_stock?
    stock_quantity < 10
  end
  
  def out_of_stock?
    stock_quantity.zero?
  end
  
  def display_name
    "#{name} (#{sku})"
  end
end
```

**Model Best Practices:**
- Always add validations
- Use scopes for common queries
- Add helper methods for business logic
- Use `audited` for change tracking

---

### Step 5: Run Migration

```bash
# Run migration
docker compose exec web rails db:migrate

# Check migration status
docker compose exec web rails db:migrate:status

# If something goes wrong, rollback
docker compose exec web rails db:rollback
```

**Verify in console:**

```bash
docker compose exec web rails console

# Check table exists
Product.connection.table_exists?('products')
# => true

# Check columns
Product.column_names
# => ["id", "name", "sku", "description", ...]
```

---

### Step 6: Create Seeds (Optional but Recommended)

```ruby
# db/seeds.rb

# Add at the end of file
puts "Creating products..."

electronics = Category.find_or_create_by!(name: 'Electronics')
tools = Category.find_or_create_by!(name: 'Tools')

products_data = [
  {
    name: 'Laptop Dell XPS 15',
    sku: 'ELEC-001',
    description: 'High-performance laptop',
    unit_price: 1500.00,
    stock_quantity: 25,
    category: electronics
  },
  {
    name: 'Hammer Heavy Duty',
    sku: 'TOOL-001',
    description: 'Professional hammer',
    unit_price: 25.50,
    stock_quantity: 100,
    category: tools
  }
]

products_data.each do |data|
  Product.find_or_create_by!(sku: data[:sku]) do |product|
    product.name = data[:name]
    product.description = data[:description]
    product.unit_price = data[:unit_price]
    product.stock_quantity = data[:stock_quantity]
    product.category = data[:category]
  end
end

puts "✅ Created #{Product.count} products"
```

**Run seeds:**

```bash
docker compose exec web rails db:seed

# Or reset database completely (development only!)
docker compose exec web rails db:reset
```

---

### Step 7: Create Policy (Authorization)

```bash
# Generate policy
docker compose exec web rails generate pundit:policy Product
```

**Edit the policy:**

```ruby
# app/policies/product_policy.rb
class ProductPolicy < ApplicationPolicy
  def index?
    user.present? # All authenticated users can view list
  end

  def show?
    user.present? # All authenticated users can view details
  end

  def create?
    user.role.name.in?(['Superadmin', 'Manager'])
  end

  def update?
    user.role.name.in?(['Superadmin', 'Manager'])
  end

  def destroy?
    user.role.name == 'Superadmin' # Only superadmin can delete
  end

  class Scope < Scope
    def resolve
      if user.role.name == 'Superadmin'
        scope.all
      else
        scope.active # Regular users only see active products
      end
    end
  end
end
```

**Read more:** [Pundit Authorization Guide](PUNDIT_AUTHORIZATION.md)

---

### Step 8: Create Service (Optional for Complex Logic)

Create service if business logic is complex or reusable.

```bash
# Create service file manually
mkdir -p app/services
touch app/services/product_stock_updater.rb
```

```ruby
# app/services/product_stock_updater.rb
class ProductStockUpdater
  def initialize(product)
    @product = product
  end

  def increase(quantity, reason:)
    @product.with_lock do
      @product.stock_quantity += quantity
      @product.save!
      
      create_transaction(quantity, 'in', reason)
    end
  end

  def decrease(quantity, reason:)
    @product.with_lock do
      raise 'Insufficient stock' if @product.stock_quantity < quantity
      
      @product.stock_quantity -= quantity
      @product.save!
      
      create_transaction(quantity, 'out', reason)
    end
  end

  private

  def create_transaction(quantity, type, reason)
    InventoryTransaction.create!(
      product: @product,
      quantity: quantity,
      transaction_type: type,
      reason: reason,
      user: Current.user
    )
  end
end
```

**When to use services:**
- ✅ Complex business logic
- ✅ Multiple model interactions
- ✅ Reusable operations
- ✅ External API calls

**When NOT to use services:**
- ❌ Simple CRUD operations
- ❌ Single model updates
- ❌ Direct database queries

---

### Step 9: Add Routes

```ruby
# config/routes.rb

Rails.application.routes.draw do
  # ... existing routes ...
  
  # Products resource
  resources :products do
    member do
      patch :activate
      patch :deactivate
    end
    collection do
      get :low_stock
      get :export
    end
  end
  
  # Or nest under a namespace
  namespace :inventory do
    resources :products
  end
end
```

**Check routes:**

```bash
docker compose exec web rails routes | grep product
```

**Route Patterns:**
- `resources :products` → Standard CRUD (index, show, new, create, edit, update, destroy)
- `member` → Routes for single resource (/products/:id/activate)
- `collection` → Routes for collection (/products/low_stock)

---

### Step 10: Generate Controller

```bash
# Generate controller
docker compose exec web rails generate controller Products \
  index show new create edit update destroy

# Creates: app/controllers/products_controller.rb
```

**Edit the controller:**

```ruby
# app/controllers/products_controller.rb
class ProductsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product, only: [:show, :edit, :update, :destroy]
  
  # GET /products
  def index
    @products = policy_scope(Product).includes(:category)
                                      .order(created_at: :desc)
                                      .page(params[:page])
    authorize Product
  end

  # GET /products/:id
  def show
    authorize @product
  end

  # GET /products/new
  def new
    @product = Product.new
    authorize @product
  end

  # POST /products
  def create
    @product = Product.new(product_params)
    authorize @product

    if @product.save
      redirect_to @product, notice: 'Product was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /products/:id/edit
  def edit
    authorize @product
  end

  # PATCH/PUT /products/:id
  def update
    authorize @product

    if @product.update(product_params)
      redirect_to @product, notice: 'Product was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /products/:id
  def destroy
    authorize @product
    
    if @product.destroy
      redirect_to products_url, notice: 'Product was successfully deleted.'
    else
      redirect_to products_url, alert: 'Cannot delete product with transactions.'
    end
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(
      :name, :sku, :description, :unit_price, 
      :stock_quantity, :category_id, :is_active
    )
  end
end
```

**Controller Best Practices:**
- Always use `authorize` for Pundit
- Use `before_action` for common operations
- Strong parameters for security
- Use `includes` to avoid N+1 queries
- Proper HTTP status codes
- Flash messages for user feedback

---

### Step 11: Create Views

#### Index View (List)

```erb
<%# app/views/products/index.html.erb %>

<div class="container mt-4">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <h1>Products</h1>
    <% if policy(Product).create? %>
      <%= link_to 'New Product', new_product_path, class: 'btn btn-primary' %>
    <% end %>
  </div>

  <div class="card">
    <div class="card-body">
      <table class="table table-hover">
        <thead>
          <tr>
            <th>SKU</th>
            <th>Name</th>
            <th>Category</th>
            <th>Price</th>
            <th>Stock</th>
            <th>Status</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <% @products.each do |product| %>
            <tr>
              <td><%= product.sku %></td>
              <td><%= link_to product.name, product %></td>
              <td><%= product.category.name %></td>
              <td><%= number_to_currency(product.unit_price) %></td>
              <td>
                <span class="badge <%= product.low_stock? ? 'bg-warning' : 'bg-success' %>">
                  <%= product.stock_quantity %>
                </span>
              </td>
              <td>
                <% if product.is_active %>
                  <span class="badge bg-success">Active</span>
                <% else %>
                  <span class="badge bg-secondary">Inactive</span>
                <% end %>
              </td>
              <td>
                <%= link_to 'View', product, class: 'btn btn-sm btn-info' %>
                <% if policy(product).update? %>
                  <%= link_to 'Edit', edit_product_path(product), class: 'btn btn-sm btn-warning' %>
                <% end %>
                <% if policy(product).destroy? %>
                  <%= link_to 'Delete', product, 
                      data: { turbo_method: :delete, turbo_confirm: 'Are you sure?' },
                      class: 'btn btn-sm btn-danger' %>
                <% end %>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
      
      <%# Pagination %>
      <%= paginate @products %>
    </div>
  </div>
</div>
```

#### Form Partial

```erb
<%# app/views/products/_form.html.erb %>

<%= form_with(model: product, local: true) do |form| %>
  <% if product.errors.any? %>
    <div class="alert alert-danger">
      <h4><%= pluralize(product.errors.count, "error") %> prohibited this product from being saved:</h4>
      <ul>
        <% product.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="mb-3">
    <%= form.label :name, class: 'form-label' %>
    <%= form.text_field :name, class: 'form-control', required: true %>
  </div>

  <div class="mb-3">
    <%= form.label :sku, class: 'form-label' %>
    <%= form.text_field :sku, class: 'form-control', required: true %>
  </div>

  <div class="mb-3">
    <%= form.label :description, class: 'form-label' %>
    <%= form.text_area :description, rows: 4, class: 'form-control' %>
  </div>

  <div class="row">
    <div class="col-md-6">
      <div class="mb-3">
        <%= form.label :unit_price, class: 'form-label' %>
        <%= form.number_field :unit_price, step: 0.01, class: 'form-control', required: true %>
      </div>
    </div>
    
    <div class="col-md-6">
      <div class="mb-3">
        <%= form.label :stock_quantity, class: 'form-label' %>
        <%= form.number_field :stock_quantity, class: 'form-control', required: true %>
      </div>
    </div>
  </div>

  <div class="mb-3">
    <%= form.label :category_id, class: 'form-label' %>
    <%= form.collection_select :category_id, Category.all, :id, :name, 
        { prompt: 'Select category' }, { class: 'form-select', required: true } %>
  </div>

  <div class="mb-3 form-check">
    <%= form.check_box :is_active, class: 'form-check-input' %>
    <%= form.label :is_active, 'Active', class: 'form-check-label' %>
  </div>

  <div class="actions">
    <%= form.submit class: 'btn btn-primary' %>
    <%= link_to 'Cancel', products_path, class: 'btn btn-secondary' %>
  </div>
<% end %>
```

#### New View

```erb
<%# app/views/products/new.html.erb %>

<div class="container mt-4">
  <h1>New Product</h1>
  <%= render 'form', product: @product %>
</div>
```

#### Edit View

```erb
<%# app/views/products/edit.html.erb %>

<div class="container mt-4">
  <h1>Edit Product</h1>
  <%= render 'form', product: @product %>
</div>
```

#### Show View

```erb
<%# app/views/products/show.html.erb %>

<div class="container mt-4">
  <div class="card">
    <div class="card-header d-flex justify-content-between align-items-center">
      <h2><%= @product.name %></h2>
      <div>
        <% if policy(@product).update? %>
          <%= link_to 'Edit', edit_product_path(@product), class: 'btn btn-warning' %>
        <% end %>
        <%= link_to 'Back', products_path, class: 'btn btn-secondary' %>
      </div>
    </div>
    
    <div class="card-body">
      <dl class="row">
        <dt class="col-sm-3">SKU:</dt>
        <dd class="col-sm-9"><%= @product.sku %></dd>

        <dt class="col-sm-3">Category:</dt>
        <dd class="col-sm-9"><%= @product.category.name %></dd>

        <dt class="col-sm-3">Description:</dt>
        <dd class="col-sm-9"><%= @product.description %></dd>

        <dt class="col-sm-3">Unit Price:</dt>
        <dd class="col-sm-9"><%= number_to_currency(@product.unit_price) %></dd>

        <dt class="col-sm-3">Stock Quantity:</dt>
        <dd class="col-sm-9">
          <span class="badge <%= @product.low_stock? ? 'bg-warning' : 'bg-success' %>">
            <%= @product.stock_quantity %>
          </span>
          <% if @product.low_stock? %>
            <small class="text-warning">Low stock!</small>
          <% end %>
        </dd>

        <dt class="col-sm-3">Status:</dt>
        <dd class="col-sm-9">
          <% if @product.is_active %>
            <span class="badge bg-success">Active</span>
          <% else %>
            <span class="badge bg-secondary">Inactive</span>
          <% end %>
        </dd>
      </dl>
    </div>
  </div>
</div>
```

---

### Step 12: Add Navigation Link

```erb
<%# app/views/layouts/application.html.erb or _navigation.html.erb %>

<nav class="navbar navbar-expand-lg navbar-dark bg-dark">
  <div class="container-fluid">
    <!-- ... existing nav items ... -->
    
    <% if user_signed_in? %>
      <li class="nav-item">
        <%= link_to 'Products', products_path, class: 'nav-link' %>
      </li>
    <% end %>
  </div>
</nav>
```

---

### Step 13: Write Tests

#### Model Test

```ruby
# test/models/product_test.rb
require "test_helper"

class ProductTest < ActiveSupport::TestCase
  def setup
    @category = categories(:electronics)
    @product = Product.new(
      name: "Test Product",
      sku: "TEST-001",
      unit_price: 100.00,
      stock_quantity: 50,
      category: @category
    )
  end

  test "should be valid with valid attributes" do
    assert @product.valid?
  end

  test "should require name" do
    @product.name = nil
    assert_not @product.valid?
    assert_includes @product.errors[:name], "can't be blank"
  end

  test "should require unique SKU" do
    @product.save!
    duplicate = @product.dup
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:sku], "has already been taken"
  end

  test "should require positive unit price" do
    @product.unit_price = -10
    assert_not @product.valid?
  end

  test "low_stock? should return true when quantity < 10" do
    @product.stock_quantity = 5
    assert @product.low_stock?
  end

  test "low_stock? should return false when quantity >= 10" do
    @product.stock_quantity = 15
    assert_not @product.low_stock?
  end
end
```

#### Controller Test

```ruby
# test/controllers/products_controller_test.rb
require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @superadmin = users(:superadmin)
    @clerk = users(:clerk)
    @product = products(:laptop)
  end

  test "should get index when signed in" do
    sign_in @clerk
    get products_url
    assert_response :success
  end

  test "should redirect to sign in when not authenticated" do
    get products_url
    assert_redirected_to new_user_session_path
  end

  test "should create product when authorized" do
    sign_in @superadmin
    
    assert_difference('Product.count', 1) do
      post products_url, params: {
        product: {
          name: "New Product",
          sku: "NEW-001",
          unit_price: 99.99,
          stock_quantity: 100,
          category_id: categories(:electronics).id
        }
      }
    end

    assert_redirected_to product_path(Product.last)
  end

  test "should not create product when unauthorized" do
    sign_in @clerk
    
    assert_no_difference('Product.count') do
      post products_url, params: {
        product: {
          name: "New Product",
          sku: "NEW-001",
          unit_price: 99.99,
          stock_quantity: 100,
          category_id: categories(:electronics).id
        }
      }
    end

    assert_response :forbidden
  end
end
```

#### Fixtures

```yaml
# test/fixtures/products.yml
laptop:
  name: "Laptop Dell XPS 15"
  sku: "ELEC-001"
  description: "High-performance laptop"
  unit_price: 1500.00
  stock_quantity: 25
  category: electronics
  is_active: true

hammer:
  name: "Hammer Heavy Duty"
  sku: "TOOL-001"
  description: "Professional hammer"
  unit_price: 25.50
  stock_quantity: 5
  category: tools
  is_active: true
```

**Run tests:**

```bash
# Run all tests
docker compose exec web rails test

# Run specific test file
docker compose exec web rails test test/models/product_test.rb

# Run specific test
docker compose exec web rails test test/models/product_test.rb:10
```

---

### Step 14: Manual Testing

```bash
# 1. Start Rails server (if not running)
docker compose up

# 2. Open browser
http://localhost:3000

# 3. Sign in as different roles
# Superadmin: admin@example.com / password
# Manager: manager@example.com / password
# Clerk: clerk@example.com / password

# 4. Test functionality
✅ List products
✅ View product details
✅ Create new product (as Superadmin/Manager)
✅ Edit product (as Superadmin/Manager)
✅ Delete product (as Superadmin only)
✅ Try as Clerk (should not see create/edit/delete buttons)
✅ Check validation errors
✅ Check flash messages
```

---

### Step 15: Run Code Quality Checks

```bash
# Run RuboCop (code style checker)
docker compose exec web rubocop

# Auto-fix simple issues
docker compose exec web rubocop -A

# Run security audit
docker compose exec web bundle audit

# Run Brakeman (security scanner)
docker compose exec web brakeman
```

---

### Step 16: Commit Your Changes

```bash
# Check what changed
git status

# Add files
git add .

# Commit with meaningful message
git commit -m "feat: add product management with CRUD operations

- Create products table with migration
- Add Product model with validations and scopes
- Implement ProductPolicy for authorization
- Add ProductsController with all CRUD actions
- Create views for index, show, new, edit
- Add tests for model and controller
- Update navigation with products link

Closes #123"

# Push to remote
git push origin feature/123-add-product-management
```

**Commit Message Format:**
```
<type>: <subject>

<body>

<footer>
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

---

### Step 17: Create Pull Request

1. **Go to GitHub/GitLab**
2. **Click "New Pull Request"**
3. **Fill in PR template:**

```markdown
## Description
Adds complete product management functionality with CRUD operations.

Closes #123

## Type of Change
- [x] New feature (non-breaking change which adds functionality)
- [ ] Bug fix
- [ ] Breaking change
- [ ] Documentation update

## How Has This Been Tested?
- [x] Unit tests (Product model)
- [x] Controller tests
- [x] Manual testing as Superadmin
- [x] Manual testing as Manager
- [x] Manual testing as Clerk
- [x] Tested authorization (Pundit policies)

## Checklist
- [x] Code follows style guidelines (RuboCop passed)
- [x] Self-reviewed my code
- [x] Commented complex code
- [x] Updated documentation
- [x] No new warnings
- [x] Added tests
- [x] All tests pass
- [x] Database migration tested

## Screenshots
[Attach screenshots of products list, create form, edit form]
```

4. **Request reviewers**
5. **Wait for approval**
6. **Address review comments**
7. **Merge to develop**

---

## Testing Guidelines

### What to Test

1. **Model Tests:**
   - ✅ Validations
   - ✅ Associations
   - ✅ Scopes
   - ✅ Instance methods
   - ✅ Class methods

2. **Controller Tests:**
   - ✅ Authentication required
   - ✅ Authorization (different roles)
   - ✅ Successful CRUD operations
   - ✅ Failed operations (validation errors)
   - ✅ Redirects and responses

3. **Integration Tests:**
   - ✅ Full user workflows
   - ✅ Multi-step processes

4. **System Tests (Optional):**
   - ✅ Browser-based testing
   - ✅ JavaScript interactions

### Test Fixtures

Create realistic test data:

```yaml
# test/fixtures/users.yml
superadmin:
  email: "admin@test.com"
  encrypted_password: <%= Devise::Encryptor.digest(User, 'password') %>
  role: superadmin_role
  name: "Admin User"

clerk:
  email: "clerk@test.com"
  encrypted_password: <%= Devise::Encryptor.digest(User, 'password') %>
  role: clerk_role
  name: "Clerk User"
```

---

## Code Review Checklist

### Before Requesting Review

- [ ] All tests pass
- [ ] RuboCop passes
- [ ] No debugger statements (byebug, binding.pry)
- [ ] No commented code
- [ ] Migrations are reversible
- [ ] Seeds work correctly
- [ ] Documentation updated
- [ ] Commit messages are clear

### Reviewer Checklist

- [ ] Code is readable and maintainable
- [ ] Follows Rails conventions
- [ ] Security: No SQL injection, XSS vulnerabilities
- [ ] Performance: No N+1 queries
- [ ] Authorization implemented correctly
- [ ] Tests are meaningful
- [ ] Error handling present
- [ ] UI is user-friendly

---

## Common Patterns

### Pattern 1: Soft Delete

```ruby
# Migration
add_column :products, :deleted_at, :datetime
add_index :products, :deleted_at

# Model
class Product < ApplicationRecord
  scope :active, -> { where(deleted_at: nil) }
  
  def soft_delete
    update(deleted_at: Time.current)
  end
  
  def restore
    update(deleted_at: nil)
  end
end

# Controller
def destroy
  @product.soft_delete
  redirect_to products_url, notice: 'Product archived.'
end
```

### Pattern 2: Search & Filter

```ruby
# Controller
def index
  @products = policy_scope(Product)
  @products = @products.where(category_id: params[:category_id]) if params[:category_id].present?
  @products = @products.where("name ILIKE ?", "%#{params[:search]}%") if params[:search].present?
  @products = @products.order(created_at: :desc).page(params[:page])
end

# View
<%= form_with url: products_path, method: :get, local: true do |f| %>
  <%= f.text_field :search, placeholder: "Search products..." %>
  <%= f.select :category_id, Category.pluck(:name, :id), include_blank: "All Categories" %>
  <%= f.submit "Filter" %>
<% end %>
```

### Pattern 3: Bulk Operations

```ruby
# Controller
def bulk_activate
  authorize Product, :update?
  Product.where(id: params[:product_ids]).update_all(is_active: true)
  redirect_to products_url, notice: "Products activated."
end

# View
<%= form_with url: bulk_activate_products_path, method: :patch do |f| %>
  <% @products.each do |product| %>
    <%= check_box_tag 'product_ids[]', product.id %>
  <% end %>
  <%= f.submit "Activate Selected" %>
<% end %>
```

### Pattern 4: Export to CSV/Excel

```ruby
# Controller
def export
  @products = policy_scope(Product)
  
  respond_to do |format|
    format.csv do
      send_data @products.to_csv, filename: "products-#{Date.today}.csv"
    end
    format.xlsx do
      send_data @products.to_xlsx, filename: "products-#{Date.today}.xlsx"
    end
  end
end

# Model
def self.to_csv
  CSV.generate(headers: true) do |csv|
    csv << ['SKU', 'Name', 'Price', 'Stock']
    all.each do |product|
      csv << [product.sku, product.name, product.unit_price, product.stock_quantity]
    end
  end
end
```

---

## Troubleshooting

### Common Errors

#### 1. Migration Error: "PG::UndefinedColumn"

```
Error: column "category_id" does not exist
```

**Solution:**
```bash
# Check migration ran
docker compose exec web rails db:migrate:status

# Run migration
docker compose exec web rails db:migrate

# If still fails, check migration file
```

#### 2. Routing Error: "No route matches"

```
ActionController::RoutingError: No route matches [GET] "/products"
```

**Solution:**
```bash
# Check routes
docker compose exec web rails routes | grep product

# Ensure routes.rb has:
resources :products
```

#### 3. Authorization Error: "Pundit::NotAuthorizedError"

```
Pundit::NotAuthorizedError
```

**Solution:**
```ruby
# Add authorize in controller
def index
  authorize Product  # Add this
  @products = Product.all
end

# Check policy exists
# app/policies/product_policy.rb
```

#### 4. N+1 Query Problem

```
WARN: Detected N+1 query
```

**Solution:**
```ruby
# Bad
@products = Product.all
@products.each { |p| p.category.name } # N+1!

# Good
@products = Product.includes(:category).all
```

#### 5. Form Not Submitting

**Solution:**
```erb
<%# Ensure authenticity token %>
<%= form_with model: @product do |f| %>
  <%# Rails adds CSRF token automatically %>
<% end %>
```

---

## Best Practices

### 1. Keep Controllers Thin

```ruby
# ❌ Bad - Fat controller
def create
  @product = Product.new(product_params)
  @product.stock_quantity = params[:initial_stock]
  @product.save
  InventoryTransaction.create(...)
  ProductLog.create(...)
  NotificationMailer.product_created(@product).deliver_later
  redirect_to @product
end

# ✅ Good - Thin controller
def create
  @product = ProductCreator.new(product_params, current_user).call
  redirect_to @product, notice: 'Product created.'
rescue ActiveRecord::RecordInvalid
  render :new
end
```

### 2. Use Concerns for Shared Behavior

```ruby
# app/models/concerns/searchable.rb
module Searchable
  extend ActiveSupport::Concern

  included do
    scope :search, ->(query) {
      where("name ILIKE ?", "%#{query}%")
    }
  end
end

# app/models/product.rb
class Product < ApplicationRecord
  include Searchable
end
```

### 3. Use Partials for Reusable Views

```erb
<%# app/views/shared/_error_messages.html.erb %>
<% if object.errors.any? %>
  <div class="alert alert-danger">
    <%= pluralize(object.errors.count, "error") %>
    <ul>
      <% object.errors.full_messages.each do |msg| %>
        <li><%= msg %></li>
      <% end %>
    </ul>
  </div>
<% end %>

<%# Usage %>
<%= render 'shared/error_messages', object: @product %>
```

### 4. Use Helpers for View Logic

```ruby
# app/helpers/products_helper.rb
module ProductsHelper
  def stock_badge(product)
    if product.out_of_stock?
      content_tag :span, 'Out of Stock', class: 'badge bg-danger'
    elsif product.low_stock?
      content_tag :span, 'Low Stock', class: 'badge bg-warning'
    else
      content_tag :span, 'In Stock', class: 'badge bg-success'
    end
  end
end

<%# View %>
<%= stock_badge(@product) %>
```

### 5. Use Background Jobs for Long Tasks

```ruby
# app/jobs/product_export_job.rb
class ProductExportJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find(user_id)
    csv = Product.to_csv
    ProductMailer.export_ready(user, csv).deliver_now
  end
end

# Controller
def export
  ProductExportJob.perform_later(current_user.id)
  redirect_to products_path, notice: 'Export started. You will receive an email.'
end
```

---

## Summary

### Quick Checklist

**Planning:**
- [ ] Understand requirements
- [ ] Design database schema
- [ ] Identify relationships

**Database:**
- [ ] Create migration
- [ ] Generate model
- [ ] Run migration
- [ ] Add seeds

**Business Logic:**
- [ ] Add validations
- [ ] Add associations
- [ ] Create policy
- [ ] Create service (if needed)

**Routes & Controller:**
- [ ] Add routes
- [ ] Generate controller
- [ ] Implement actions
- [ ] Strong parameters

**Views:**
- [ ] Create index view
- [ ] Create form partial
- [ ] Create show view
- [ ] Add navigation

**Testing:**
- [ ] Write model tests
- [ ] Write controller tests
- [ ] Manual testing
- [ ] Fix bugs

**Quality:**
- [ ] Run RuboCop
- [ ] Run tests
- [ ] Update docs

**Deploy:**
- [ ] Commit changes
- [ ] Push to remote
- [ ] Create PR
- [ ] Merge to develop

---

**Related Documentation:**
- [Quick Start Guide](QUICK_START.md)
- [Git Branching Strategy](GIT_BRANCHING_STRATEGY.md)
- [Pundit Authorization](PUNDIT_AUTHORIZATION.md)
- [Devise Authentication](DEVISE_GUIDE.md)
- [Audited Usage](AUDITED_USAGE.md)

**Last Updated:** October 28, 2025  
**Project:** ST Intent Harvest  
**Team:** Development Team
