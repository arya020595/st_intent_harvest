# Export Services Architecture Guide

A comprehensive guide for implementing CSV and PDF export functionality using our SOLID-based export architecture.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [SOLID Principles Applied](#solid-principles-applied)
4. [When to Use](#when-to-use)
5. [Quick Start](#quick-start)
6. [Step-by-Step Implementation](#step-by-step-implementation)
7. [API Reference](#api-reference)
8. [Examples](#examples)
9. [Best Practices](#best-practices)
10. [Troubleshooting](#troubleshooting)

---

## Overview

### What is This?

The Export Services Architecture is a reusable, standardized framework for generating CSV and PDF exports across all modules in our application. Instead of writing export logic from scratch for each module, developers extend base classes and only implement module-specific details.

### Key Benefits

| Benefit             | Description                                                              |
| ------------------- | ------------------------------------------------------------------------ |
| **Consistency**     | All exports follow the same pattern and return the same Result structure |
| **Reusability**     | Generic exporters handle common logic; you only write what's unique      |
| **Maintainability** | Changes to core export logic propagate to all modules                    |
| **Testability**     | Each component has single responsibility, easy to unit test              |
| **Extensibility**   | Add new export formats (Excel, JSON) by extending BaseExporter           |

---

## Architecture

### Directory Structure

```
app/services/
├── exporters/                              # 🔧 Generic (DO NOT MODIFY)
│   ├── format_helpers.rb                   # Shared formatting utilities
│   ├── base_exporter.rb                    # Abstract base class
│   ├── csv_exporter.rb                     # CSV generation logic
│   └── pdf_exporter.rb                     # PDF generation with Grover
│
├── production_services/                    # 📦 Module-specific
│   ├── export_csv_service.rb              # Productions CSV export
│   └── export_pdf_service.rb              # Productions PDF export
│
├── harvest_services/                       # 📦 Module-specific (example)
│   ├── export_csv_service.rb
│   └── export_pdf_service.rb
│
└── [your_module]_services/                 # 📦 Your new module
    ├── export_csv_service.rb
    └── export_pdf_service.rb
```

### Class Hierarchy

```
Exporters::FormatHelpers (Module)
    │
    └── included in ──►  Exporters::BaseExporter (Abstract)
                              │
                              ├── Exporters::CsvExporter
                              │       │
                              │       └── ProductionServices::ExportCsvService
                              │       └── HarvestServices::ExportCsvService
                              │       └── [YourModule]Services::ExportCsvService
                              │
                              └── Exporters::PdfExporter
                                      │
                                      └── ProductionServices::ExportPdfService
                                      └── HarvestServices::ExportPdfService
                                      └── [YourModule]Services::ExportPdfService
```

### Data Flow

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────┐     ┌──────────┐
│  Controller │────►│  Export Service  │────►│  Base Exporter  │────►│  Result  │
│   (call)    │     │ (module-specific)│     │  (generate)     │     │ (return) │
└─────────────┘     └──────────────────┘     └─────────────────┘     └──────────┘
                                                      │
                                                      ▼
                                            ┌─────────────────┐
                                            │ FormatHelpers   │
                                            │ (formatting)    │
                                            └─────────────────┘
```

---

## SOLID Principles Applied

### S - Single Responsibility

Each class has ONE job:

| Class                                  | Responsibility                         |
| -------------------------------------- | -------------------------------------- |
| `FormatHelpers`                        | Format dates, numbers, currencies      |
| `BaseExporter`                         | Orchestrate export flow, handle errors |
| `CsvExporter`                          | Generate CSV files                     |
| `PdfExporter`                          | Generate PDF files using Grover        |
| `ProductionServices::ExportCsvService` | Define production-specific CSV mapping |

### O - Open/Closed

- **Closed for modification**: Don't change `Exporters::CsvExporter` or `Exporters::PdfExporter`
- **Open for extension**: Create new services by extending these classes

### L - Liskov Substitution

All exporters return `Dry::Monads::Result` (Success/Failure):

```ruby
# Success case
result.success?  # => true
result.value!    # => { data: "...", filename: "...", content_type: "..." }

# Failure case
result.success?  # => false
result.failure   # => "Error message"
```

Any exporter can be used interchangeably in controllers.

### I - Interface Segregation

Subclasses only implement what they need:

| CSV Exporter     | PDF Exporter       |
| ---------------- | ------------------ |
| `#resource_name` | `#resource_name`   |
| `#headers`       | `#template_path`   |
| `#row_data`      | `#template_locals` |

### D - Dependency Inversion

- Controllers depend on abstract `Result` struct, not concrete implementations
- PDF exporter depends on `view_context` abstraction, not specific controller

---

## When to Use

### ✅ USE This Architecture When:

- Adding CSV or PDF export to a module
- Module has an index page with filterable data
- Export needs to respect current filters
- You want consistent filename patterns
- You need error handling for exports

### ❌ DON'T USE When:

- One-off data dump (use direct CSV generation)
- Export logic is completely unique with no commonality
- Exporting to formats other than CSV/PDF (extend BaseExporter instead)

---

## Quick Start

### 1. Create CSV Export (5 minutes)

```ruby
# app/services/harvest_services/export_csv_service.rb
module HarvestServices
  class ExportCsvService < Exporters::CsvExporter
    HEADERS = ['Date', 'Block', 'Worker', 'Weight (kg)'].freeze

    protected

    def resource_name
      'harvests'
    end

    def headers
      HEADERS
    end

    def row_data(harvest)
      [
        format_date(harvest.date),
        harvest.block.name,
        harvest.worker.full_name,
        format_decimal(harvest.weight)
      ]
    end
  end
end
```

### 2. Create PDF Export (3 minutes)

```ruby
# app/services/harvest_services/export_pdf_service.rb
module HarvestServices
  class ExportPdfService < Exporters::PdfExporter
    protected

    def resource_name
      'harvests'
    end

    def template_path
      'harvests/index'
    end

    def template_locals
      { harvests: @records, params: @params }
    end
  end
end
```

### 3. Create PDF Template

```erb
<!-- app/views/harvests/index.pdf.erb -->
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Harvest Report</title>
  <style>
    /* Your PDF styles here */
  </style>
</head>
<body>
  <h1>Harvest Report</h1>
  <table>
    <thead>
      <tr>
        <th>Date</th>
        <th>Block</th>
        <th>Worker</th>
        <th>Weight</th>
      </tr>
    </thead>
    <tbody>
      <% harvests.each do |harvest| %>
        <tr>
          <td><%= harvest.date.strftime('%d-%m-%Y') %></td>
          <td><%= harvest.block.name %></td>
          <td><%= harvest.worker.full_name %></td>
          <td><%= number_with_precision(harvest.weight, precision: 2) %></td>
        </tr>
      <% end %>
    </tbody>
  </table>
</body>
</html>
```

### 4. Use in Controller (with ExportHandling Concern)

```ruby
# app/controllers/harvests_controller.rb
class HarvestsController < ApplicationController
  include ExportHandling  # Include the export handling concern

  def index
    @q = Harvest.ransack(params[:q])
    @harvests = @q.result.includes(:block, :worker)

    respond_to do |format|
      format.html
      format.csv { export_csv }
      format.pdf { export_pdf }
    end
  end

  private

  # Clean and DRY export methods using ExportHandling concern
  def export_csv
    handle_csv_export(
      HarvestServices::ExportCsvService,
      @q.result.includes(:block, :worker),
      error_path: harvests_path
    )
  end

  def export_pdf
    handle_pdf_export(
      HarvestServices::ExportPdfService,
      @q.result.includes(:block, :worker),
      error_path: harvests_path
    )
  end
end
```

#### Alternative: Manual Dry::Monads Handling

If you prefer manual control over the result:

```ruby
def export_csv
  result = HarvestServices::ExportCsvService.new(
    records: @q.result.includes(:block, :worker),
    params: params
  ).call

  if result.success?
    export_data = result.value!  # Get the success value hash
    send_data export_data[:data], filename: export_data[:filename], type: export_data[:content_type]
  else
    redirect_to harvests_path, alert: "CSV export failed: #{result.failure}"
  end
end
```

---

## Step-by-Step Implementation

### Step 1: Plan Your Export

Before coding, answer these questions:

| Question                         | Example Answer              |
| -------------------------------- | --------------------------- |
| What module is this for?         | `Harvests`                  |
| What columns for CSV?            | Date, Block, Worker, Weight |
| What filters should show in PDF? | Date range, Block, Worker   |
| Portrait or Landscape PDF?       | Landscape (wide table)      |

### Step 2: Create Service Directory

```bash
mkdir -p app/services/harvest_services
```

### Step 3: Create CSV Service

Create file: `app/services/harvest_services/export_csv_service.rb`

```ruby
# frozen_string_literal: true

module HarvestServices
  class ExportCsvService < Exporters::CsvExporter
    # Define your column headers
    HEADERS = [
      'Date',
      'Block',
      'Worker',
      'Weight (kg)'
    ].freeze

    protected

    # Used for filename: harvests-{date}.csv
    def resource_name
      'harvests'
    end

    def headers
      HEADERS
    end

    # Map each record to CSV row (must match HEADERS order)
    def row_data(harvest)
      [
        format_date(harvest.date),           # Uses FormatHelpers
        harvest.block.name,
        harvest.worker.full_name,
        format_decimal(harvest.weight)       # Uses FormatHelpers
      ]
    end
  end
end
```

### Step 4: Create PDF Service

Create file: `app/services/harvest_services/export_pdf_service.rb`

```ruby
# frozen_string_literal: true

module HarvestServices
  class ExportPdfService < Exporters::PdfExporter
    protected

    # Used for filename: harvests-{date}.pdf
    def resource_name
      'harvests'
    end

    # Path to your PDF template (without .pdf.erb)
    def template_path
      'harvests/index'
    end

    # Variables passed to the template
    def template_locals
      { harvests: @records, params: @params }
    end

    # Optional: Change to portrait if needed
    # def landscape?
    #   false
    # end

    # Optional: Custom PDF options
    # def pdf_options
    #   super.merge(format: 'Letter')
    # end
  end
end
```

### Step 5: Create PDF Template

Create file: `app/views/harvests/index.pdf.erb`

```erb
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Harvest Report</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      font-size: 11px;
      margin: 20px;
    }
    h1 {
      text-align: center;
      color: #155e1a;
      margin-bottom: 20px;
    }
    .info {
      text-align: center;
      margin-bottom: 20px;
      font-size: 10px;
      color: #666;
    }
    table {
      width: 100%;
      border-collapse: collapse;
    }
    th {
      background-color: #155e1a;
      color: white;
      padding: 8px;
      text-align: center;
      border: 1px solid #ddd;
    }
    td {
      padding: 6px 8px;
      border: 1px solid #ddd;
      text-align: center;
    }
    tr:nth-child(even) {
      background-color: #f9f9f9;
    }
    .total-row {
      background-color: #e8f5e9;
      font-weight: bold;
    }
    .footer {
      margin-top: 20px;
      text-align: center;
      font-size: 9px;
      color: #999;
    }
  </style>
</head>
<body>
  <h1>Harvest Report</h1>

  <div class="info">
    <%# Display active filters %>
    <% if params.dig(:q, :date_gteq).present? || params.dig(:q, :date_lteq).present? %>
      <strong>Date Range:</strong>
      <%= params.dig(:q, :date_gteq).present? ? Date.parse(params.dig(:q, :date_gteq)).strftime('%d-%m-%Y') : 'All' %>
      to
      <%= params.dig(:q, :date_lteq).present? ? Date.parse(params.dig(:q, :date_lteq)).strftime('%d-%m-%Y') : 'All' %>
      <br>
    <% end %>

    <strong>Generated:</strong> <%= Time.current.strftime('%d-%m-%Y %H:%M') %><br>
    <strong>Total Records:</strong> <%= harvests.count %>
  </div>

  <table>
    <thead>
      <tr>
        <th>No.</th>
        <th>Date</th>
        <th>Block</th>
        <th>Worker</th>
        <th>Weight (kg)</th>
      </tr>
    </thead>
    <tbody>
      <% harvests.each_with_index do |harvest, index| %>
        <tr>
          <td><%= index + 1 %></td>
          <td><%= harvest.date.strftime('%d-%m-%Y') %></td>
          <td><%= harvest.block.name %></td>
          <td><%= harvest.worker.full_name %></td>
          <td><%= number_with_precision(harvest.weight, precision: 2) %></td>
        </tr>
      <% end %>

      <% if harvests.any? %>
        <tr class="total-row">
          <td colspan="4" style="text-align: right;">Total:</td>
          <td><%= number_with_precision(harvests.sum(:weight), precision: 2) %></td>
        </tr>
      <% end %>
    </tbody>
  </table>

  <div class="footer">
    Harvest Report - Generated on <%= Time.current.strftime('%d %B %Y at %H:%M') %>
  </div>
</body>
</html>
```

### Step 6: Update Controller

```ruby
class HarvestsController < ApplicationController
  include ExportHandling  # Use the export handling concern

  def index
    @q = Harvest.ransack(params[:q])
    @pagy, @harvests = pagy(@q.result.includes(:block, :worker))

    respond_to do |format|
      format.html
      format.csv { export_csv }
      format.pdf { export_pdf }
    end
  end

  private

  def export_csv
    handle_csv_export(
      HarvestServices::ExportCsvService,
      @q.result.includes(:block, :worker),
      error_path: harvests_path
    )
  end

  def export_pdf
    handle_pdf_export(
      HarvestServices::ExportPdfService,
      @q.result.includes(:block, :worker),
      error_path: harvests_path
    )
  end
end
```

### Step 7: Add Export Buttons to View

```erb
<!-- app/views/harvests/index.html.erb -->
<div class="d-flex gap-2">
  <% date_filtered = params.dig(:q, :date_gteq).present? || params.dig(:q, :date_lteq).present? %>

  <% export_params = { format: :csv } %>
  <% export_params[:q] = params[:q].to_unsafe_h if params[:q].present? %>
  <%= link_to harvests_path(export_params),
              class: "btn btn-success btn-sm #{date_filtered ? '' : 'disabled'}",
              data: { turbo: false } do %>
    <i class="bi bi-file-earmark-spreadsheet me-1"></i> Export CSV
  <% end %>

  <% export_params_pdf = { format: :pdf } %>
  <% export_params_pdf[:q] = params[:q].to_unsafe_h if params[:q].present? %>
  <%= link_to harvests_path(export_params_pdf),
              class: "btn btn-danger btn-sm #{date_filtered ? '' : 'disabled'}",
              data: { turbo: false },
              target: "_blank" do %>
    <i class="bi bi-file-earmark-pdf me-1"></i> Export PDF
  <% end %>
</div>
```

---

## API Reference

### FormatHelpers

Available in all exporters via `include`:

| Method                                   | Description             | Example                                     |
| ---------------------------------------- | ----------------------- | ------------------------------------------- |
| `format_date(date, format = '%d-%m-%Y')` | Format date             | `format_date(record.date)` → `"20-01-2026"` |
| `format_decimal(value, precision = 2)`   | Format number           | `format_decimal(123.456)` → `"123.46"`      |
| `format_currency(value)`                 | Format as currency      | `format_currency(1000)` → `"1000.00"`       |
| `safe_value(value, default = '-')`       | Return value or default | `safe_value(nil)` → `"-"`                   |
| `number_with_delimiter(number)`          | Add thousand separators | `number_with_delimiter(1000)` → `"1,000"`   |

### BaseExporter

Includes `Dry::Monads[:result]` for Success/Failure handling.

| Method                    | Access    | Description                                   |
| ------------------------- | --------- | --------------------------------------------- |
| `#call`                   | Public    | Execute export, returns `Dry::Monads::Result` |
| `#generate_export`        | Protected | **Override**: Generate export data            |
| `#generate_filename`      | Protected | **Override**: Return filename                 |
| `#content_type`           | Protected | **Override**: Return MIME type                |
| `#file_extension`         | Protected | **Override**: Return extension                |
| `#resource_name`          | Protected | **Override**: Return resource name            |
| `#build_filename(prefix)` | Protected | Helper to build standard filename             |

### CsvExporter (extends BaseExporter)

| Method              | Access    | Description                                         |
| ------------------- | --------- | --------------------------------------------------- |
| `#headers`          | Protected | **Override**: Return array of column headers        |
| `#row_data(record)` | Protected | **Override**: Return array of values for one record |
| `#resource_name`    | Protected | **Override**: Return resource name for filename     |

### PdfExporter (extends BaseExporter)

| Method             | Access    | Description                                                     |
| ------------------ | --------- | --------------------------------------------------------------- |
| `#template_path`   | Protected | **Override**: Return template path (e.g., `'harvests/index'`)   |
| `#template_locals` | Protected | **Override**: Return hash of variables for template             |
| `#resource_name`   | Protected | **Override**: Return resource name for filename                 |
| `#landscape?`      | Protected | **Override**: Return `true` for landscape, `false` for portrait |
| `#pdf_options`     | Protected | **Override**: Return hash of Grover options                     |

### Result (Dry::Monads)

All exporters return `Dry::Monads::Result`:

```ruby
result = ExportService.new(...).call

# Success case
result.success?         # => true
export_data = result.value!
export_data[:data]       # String: The generated file content
export_data[:filename]   # String: Suggested filename
export_data[:content_type] # String: MIME type

# Failure case
result.success?         # => false
result.failure          # String: Error message
```

### ExportHandling Concern

Include in your controller for DRY export methods:

```ruby
include ExportHandling

# Available methods:
handle_csv_export(ServiceClass, records, error_path:)
handle_pdf_export(ServiceClass, records, error_path:, disposition: 'inline')
```

---

## Examples

### Example 1: Simple CSV Export

```ruby
module ItemServices
  class ExportCsvService < Exporters::CsvExporter
    HEADERS = ['Name', 'Price', 'Quantity'].freeze

    protected

    def resource_name = 'items'
    def headers = HEADERS
    def row_data(item) = [item.name, format_currency(item.price), item.quantity]
  end
end
```

### Example 2: CSV with Associations

```ruby
module OrderServices
  class ExportCsvService < Exporters::CsvExporter
    HEADERS = ['Order #', 'Customer', 'Product', 'Quantity', 'Total'].freeze

    protected

    def resource_name
      'orders'
    end

    def headers
      HEADERS
    end

    def row_data(order)
      [
        order.number,
        order.customer.name,
        order.product.name,
        order.quantity,
        format_currency(order.total)
      ]
    end
  end
end
```

### Example 3: Portrait PDF

```ruby
module InvoiceServices
  class ExportPdfService < Exporters::PdfExporter
    protected

    def resource_name = 'invoices'
    def template_path = 'invoices/show'
    def template_locals = { invoice: @records.first }

    # Portrait for invoice
    def landscape?
      false
    end

    # Custom margins
    def pdf_options
      super.merge(
        margin: { top: '20mm', bottom: '20mm', left: '15mm', right: '15mm' }
      )
    end
  end
end
```

### Example 4: PDF with Custom Options

```ruby
module ReportServices
  class ExportPdfService < Exporters::PdfExporter
    protected

    def resource_name = 'reports'
    def template_path = 'reports/summary'
    def template_locals = { data: @records, filters: @params[:q] }

    def pdf_options
      {
        format: 'A4',
        landscape: true,
        margin: { top: '15mm', bottom: '15mm', left: '10mm', right: '10mm' },
        print_background: true,
        prefer_css_page_size: true
      }
    end
  end
end
```

---

## Best Practices

### ✅ DO

1. **Always include associations in controller**

   ```ruby
   records = @q.result.includes(:block, :worker)  # Prevent N+1
   ```

2. **Use FormatHelpers for consistency**

   ```ruby
   format_date(record.date)      # Not: record.date.strftime(...)
   format_decimal(record.amount) # Not: sprintf('%.2f', record.amount)
   ```

3. **Keep services minimal** - Only override what's needed

4. **Use local variables in PDF templates**

   ```erb
   <% harvests.each do |h| %>  <!-- Use local variable -->
   ```

5. **Handle nil values**
   ```ruby
   safe_value(record.optional_field)  # Returns '-' if nil
   ```

### ❌ DON'T

1. **Don't modify base exporters** - Extend them instead

2. **Don't use instance variables in PDF templates**

   ```erb
   <% @harvests.each %>  <!-- WRONG: use local variable -->
   ```

3. **Don't duplicate formatting logic**

   ```ruby
   # WRONG
   record.date.strftime('%d-%m-%Y')

   # RIGHT
   format_date(record.date)
   ```

4. **Don't skip error handling in controller**
   ```ruby
   # Always check result.success?
   if result.success?
     send_data result.data, ...
   else
     redirect_with_error
   end
   ```

---

## Troubleshooting

### Error: "must implement #headers"

**Cause**: Your CSV service doesn't define the `headers` method.

**Fix**: Add the method:

```ruby
def headers
  ['Column1', 'Column2']
end
```

### Error: "must implement #template_path"

**Cause**: Your PDF service doesn't define the `template_path` method.

**Fix**: Add the method:

```ruby
def template_path
  'your_module/index'
end
```

### Error: "undefined local variable 'harvests'"

**Cause**: Template uses variable not passed in `template_locals`.

**Fix**: Ensure `template_locals` includes the variable:

```ruby
def template_locals
  { harvests: @records, params: @params }
end
```

### PDF is Blank

**Cause**: HTML/CSS issue or template error.

**Debug**:

1. Render HTML in browser first: `format.html { render template: 'harvests/index', formats: [:pdf] }`
2. Check for JavaScript-dependent content (won't work in PDF)

### CSV Has Wrong Encoding

**Cause**: Special characters not handled.

**Fix**: The base exporter uses UTF-8. Ensure your data is UTF-8:

```ruby
def row_data(record)
  [record.name.to_s.encode('UTF-8')]
end
```

### Filename Has Wrong Date

**Cause**: Date filter params not passed correctly.

**Fix**: Ensure params are passed to service:

```ruby
ExportCsvService.new(records: records, params: params)  # Include params!
```

---

## Changelog

| Date       | Version | Changes                                  |
| ---------- | ------- | ---------------------------------------- |
| 2026-01-20 | 1.0.0   | Initial release with CSV and PDF support |

---

## Contact

For questions or suggestions about this architecture, contact the development team.
