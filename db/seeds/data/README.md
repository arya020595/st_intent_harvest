# Seeds Documentation

## Overview

The seeding system follows SOLID principles, making it maintainable, testable, and scalable. Each domain context is isolated in its own module with optimized database queries.

**Note:** Seeding is only available in development/test environments. Production data should be managed via dedicated rake tasks.

## Architecture

### Directory Structure

```
db/seeds/
├── seeds.rb                        # Entry point (blocks production)
├── main.rb                         # Main orchestrator
└── data/                           # Modular seed files
    ├── permissions.rb              # Permission definitions
    ├── roles.rb                    # Roles with permission assignments
    ├── users.rb                    # User accounts with role assignments
    ├── deduction_types.rb          # EPF, SOCSO, EIS deduction definitions
    ├── master_data.rb              # Units, Categories, Blocks, Vehicles
    ├── workers.rb                  # Worker records
    ├── inventories.rb              # Inventory items by category
    ├── work_order_rates.rb         # Work order rate definitions
    ├── work_orders.rb              # Work orders with workers and items
    ├── pay_calculations.rb         # Pay calculations and details
    └── reset_sequences.rb          # PostgreSQL sequence reset (runs last)
```

### Design Principles

1. **Single Responsibility**: Each module handles one domain context
2. **Dependency Order**: Modules are loaded in correct dependency sequence
3. **Batch Operations**: Uses `insert_all` for bulk inserts (up to 10x faster)
4. **Optimized Queries**: Minimizes database round trips with smart caching
5. **Error Handling**: Each module can fail independently with clear error messages
6. **Idempotency**: Safe to run multiple times using `find_or_create_by!`
7. **Environment Safety**: Production seeding is blocked at entry point

## Usage

### Run Seeds (Development/Test Only)

```bash
# Standard seeding
rails db:seed

# In Docker
docker compose exec web rails db:seed
```

### Seed Specific Module (Advanced)

```ruby
# In Rails console
Audited.auditing_enabled = false

# Load specific module
load Rails.root.join('db/seeds/data/workers.rb')

Audited.auditing_enabled = true
```

## Module Details

### 1. Permissions (`permissions.rb`)

- Creates permissions across 7 sections (Dashboard, Work Order, Payslip, etc.)
- Uses `find_or_initialize_by` for idempotency

### 2. Roles (`roles.rb`)

- Creates 4 roles: Superadmin, Manager, Field Conductor, Clerk
- Uses batch `insert_all` for role-permission associations
- Fetches all permissions once, then maps by code

### 3. Users (`users.rb`)

- Creates 4 test users with default credentials
- Maps users to roles via role name lookup
- Default password: `ChangeMe123!`

### 4. Deduction Types (`deduction_types.rb`)

- EPF (Malaysian & Foreign)
- SOCSO (Malaysian & Foreign)
- EIS (Malaysian only)

### 5. Master Data (`master_data.rb`)

- **Units**: 7 measurement units (Kg, Liter, Piece, Hour, Day, Hectare, Ton)
- **Categories**: 5 inventory categories
- **Blocks**: 10 plantation blocks with hectarage
- **Vehicles**: 10 vehicles with models

### 6. Workers (`workers.rb`)

- Creates 30 worker records (27 active, 3 inactive)
- Mix of Full-Time and Part-Time workers
- Mix of Local and Foreigner nationalities

### 7. Inventories (`inventories.rb`)

- 18 inventory items across 4 categories:
  - 5 Fertilizers
  - 4 Pesticides
  - 5 Tools
  - 4 Equipment

### 8. Work Order Rates (`work_order_rates.rb`)

- 9 standardized rates:
  - 6 Day-based rates
  - 3 Hectare-based rates

### 9. Work Orders (`work_orders.rb`)

- 10 work orders with varying statuses
- Work Order Workers associations
- Work Order Items associations

### 10. Pay Calculations (`pay_calculations.rb`)

- Processes completed work orders to generate pay calculations
- Uses `PayCalculationServices::ProcessWorkOrderService` for each completed work order
- Creates pay calculation details with automatic deduction calculations

### 11. Reset Sequences (`reset_sequences.rb`)

- Resets all PostgreSQL sequences
- Prevents duplicate key errors after seeding

## Test User Credentials

| Email                  | Password     | Role            |
| ---------------------- | ------------ | --------------- |
| superadmin@example.com | ChangeMe123! | Superadmin      |
| manager@example.com    | ChangeMe123! | Manager         |
| conductor@example.com  | ChangeMe123! | Field Conductor |
| clerk@example.com      | ChangeMe123! | Clerk           |

## Adding New Seed Modules

1. Create a new file in `db/seeds/data/` (e.g., `new_module.rb`)
2. Add the module name to `seed_modules` array in `main.rb`
3. Ensure proper dependency order (add after its dependencies)
4. Follow existing patterns for consistency

## Best Practices

- Use `find_or_create_by!` for idempotent seeding
- Use `insert_all` for bulk inserts when callbacks aren't needed
- Cache lookups at the start of each module (e.g., `Unit.pluck(:name, :id).to_h`)
- Print progress messages for visibility
- Handle errors gracefully with clear messages
