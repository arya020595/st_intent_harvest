# Inventory Management with Pagy & Ransack

## Overview
The Inventory Management feature provides full CRUD operations with advanced search/filtering using Ransack and pagination using Pagy.

## Features Implemented

### 1. Pagination (Pagy)
- **Configuration**: `config/initializers/pagy.rb`
- **Items per page**: 20
- **Bootstrap 5 styling**: Uses `pagy_bootstrap_nav` helper
- **Overflow handling**: Automatically redirects to last page if out of range

### 2. Search & Filtering (Ransack)
The inventory index page includes search by:
- **Item Name**: Contains search (`name_cont`)
- **Category**: Exact match dropdown (`category_id_eq`)
- **Unit**: Exact match dropdown (`unit_id_eq`)
- **Supplier**: Contains search (`supplier_cont`)

**Sorting**: Click column headers to sort by:
- Item Name
- Stock Quantity
- Price
- Input Date

### 3. Controller Actions
**InventoriesController** (`app/controllers/inventories_controller.rb`)
- `index`: List with search and pagination
- `show`: View single item with total value calculation
- `new`: Form for creating new item
- `create`: Save new item with validation
- `edit`: Form for updating item
- `update`: Save changes with validation
- `destroy`: Delete item with confirmation

### 4. Views

#### Index (`app/views/inventories/index.html.erb`)
- Search form with filters
- Results count display
- Responsive table with:
  - Color-coded stock badges (red: out of stock, warning: <10, success: ≥10)
  - Category and unit display
  - Price with currency
  - Action buttons (view, edit, delete) based on permissions
- Bootstrap pagination at bottom

#### Show (`app/views/inventories/show.html.erb`)
- Detailed view of single item
- All fields displayed
- Total inventory value calculation (price × quantity)
- Edit and Delete buttons (permission-based)
- Timestamps (created/updated)

#### Form (`app/views/inventories/_form.html.erb`)
- Reusable partial for new/edit
- Fields:
  - Item Name (required)
  - Category (dropdown)
  - Stock Quantity (number input, min: 0)
  - Unit (dropdown)
  - Price with currency selector (RM, USD, EUR)
  - Supplier
  - Input Date
- Validation error display
- Bootstrap styling with validation feedback

#### New & Edit
- Breadcrumb navigation
- Renders form partial
- Card layout with appropriate colors

## Database Schema

**Inventories Table**:
- `id`: Primary key
- `name`: Item name (required)
- `stock_quantity`: Integer (default: 0)
- `price`: Decimal(10, 2)
- `currency`: String (default: "RM")
- `supplier`: String
- `input_date`: Date
- `category_id`: Foreign key to categories
- `unit_id`: Foreign key to units
- `created_at`, `updated_at`: Timestamps

**Relationships**:
- `belongs_to :category` (optional)
- `belongs_to :unit` (optional)
- `has_many :work_order_items`

## Permissions
All controller actions are protected by Pundit authorization:
- `Inventory#index` requires permission: `('Inventory', 'index')`
- `Inventory#show` requires permission: `('Inventory', 'show')`
- `Inventory#create` requires permission: `('Inventory', 'create')`
- `Inventory#update` requires permission: `('Inventory', 'update')`
- `Inventory#destroy` requires permission: `('Inventory', 'destroy')`

View elements (buttons, links) also check permissions before rendering.

## Usage Examples

### Searching
```ruby
# Search by name
params[:q][:name_cont] = "hammer"

# Filter by category
params[:q][:category_id_eq] = 3

# Sort by price descending
params[:q][:s] = "price desc"
```

### Controller Example
```ruby
def index
  authorize Inventory
  
  # Ransack search with associations
  @q = policy_scope(Inventory).ransack(params[:q])
  @inventories = @q.result(distinct: true).includes(:unit, :category)
  
  # Pagy pagination
  @pagy, @inventories = pagy(@inventories, items: 20)
end
```

### View Example
```erb
<!-- Search form -->
<%= search_form_for @q do |f| %>
  <%= f.search_field :name_cont %>
  <%= f.select :category_id_eq, options_from_collection_for_select(...) %>
  <%= f.submit 'Search' %>
<% end %>

<!-- Sortable column -->
<th><%= sort_link(@q, :price, 'Price') %></th>

<!-- Pagination -->
<%== pagy_bootstrap_nav(@pagy) %>
```

## Configuration Files

### Pagy Initializer
Location: `config/initializers/pagy.rb`

Key settings:
```ruby
Pagy::DEFAULT[:items]  = 20                  # Items per page
Pagy::DEFAULT[:size]   = [1,4,4,1]           # Nav bar items
Pagy::DEFAULT[:overflow] = :last_page        # Handle overflow

require 'pagy/extras/bootstrap'              # Bootstrap 5 styling
require 'pagy/extras/overflow'               # Overflow handling
```

### Application Controller
```ruby
class ApplicationController < ActionController::Base
  include Pagy::Backend  # Added for pagination
  # ...
end
```

### Application Helper
```ruby
module ApplicationHelper
  include Pagy::Frontend  # Added for pagination helpers
end
```

## Testing Access

1. **Superadmin** (superadmin@example.com): Full access to all operations
2. **Manager** (manager@example.com): May have limited access based on permissions
3. **Field Conductor** (conductor@example.com): May have limited access
4. **Clerk** (clerk@example.com): Typically has inventory management permissions

Password for all test users: `password`

## Routes
```ruby
resources :inventories  # Provides all 7 RESTful routes
```

Generated routes:
- `GET    /inventories`          → index
- `GET    /inventories/:id`      → show
- `GET    /inventories/new`      → new
- `POST   /inventories`          → create
- `GET    /inventories/:id/edit` → edit
- `PATCH  /inventories/:id`      → update
- `DELETE /inventories/:id`      → destroy

## Best Practices

1. **Always use policy_scope** in index action to respect authorization
2. **Include associations** (`.includes(:unit, :category)`) to avoid N+1 queries
3. **Use distinct** with Ransack to prevent duplicate records
4. **Check permissions** before rendering action buttons in views
5. **Provide user feedback** with flash messages on CRUD operations

## Future Enhancements

Potential improvements:
- Export to CSV/Excel
- Inventory history tracking
- Low stock alerts
- Barcode scanning integration
- Bulk import functionality
- Inventory movement logs
- Stock adjustment with reasons
