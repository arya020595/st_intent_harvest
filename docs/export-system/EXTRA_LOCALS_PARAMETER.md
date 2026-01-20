# Extra Locals Parameter - CSV vs PDF Exports

## Overview

The `extra_locals` parameter in export methods is **PDF-specific** and intentionally NOT supported by CSV exports. This document clarifies why and how to use it correctly.

## Quick Reference

| Feature                  | CSV Export         | PDF Export               |
| ------------------------ | ------------------ | ------------------------ |
| **extra_locals support** | ❌ No (ignored)    | ✅ Yes (used)            |
| **Template rendering**   | None               | HTML template via Grover |
| **Parameter usage**      | N/A                | Passed to view context   |
| **Use case**             | Plain tabular data | Rich formatted document  |

## Why CSV Doesn't Use extra_locals

CSV exports generate **plain text tabular data** without template rendering:

```ruby
# CSV is just headers + rows
ID,Name,Amount
1,Item A,100
2,Item B,200
```

Since CSV format cannot render templates or display arbitrary variables, `extra_locals` has no purpose. All CSV content must be configured through:

- **`#headers`** - Column headers
- **`#row_data`** - Row values for each record

## Why PDF Uses extra_locals

PDF exports render **HTML templates** using Grover, which converts HTML to PDF:

```erb
<!-- app/views/productions/index.pdf.erb -->
<h2><%= @filter_data.mill&.name %></h2>
<table>
  <%= render 'totals', totals: @totals %>
</table>
```

Template variables are passed via `extra_locals`:

```ruby
handle_pdf_export(
  ProductionServices::ExportPdfService,
  records,
  error_path: productions_path,
  extra_locals: {
    totals: { bunches: 1000, weight: 500 },
    filter_data: { mill: mill_obj, block: block_obj }
  }
)
```

## Correct Usage Patterns

### ✅ CSV Export - Don't Pass extra_locals

```ruby
# CORRECT: CSV only needs records
handle_csv_export(
  ProductionServices::ExportCsvService,
  records,
  error_path: productions_path
)
```

### ❌ CSV Export - Avoid Passing extra_locals

```ruby
# NOT RECOMMENDED: extra_locals will be silently ignored
handle_csv_export(
  ProductionServices::ExportCsvService,
  records,
  error_path: productions_path,
  extra_locals: { totals: {...} }  # ← This will be ignored
)
```

### ✅ PDF Export - Pass extra_locals for Template Variables

```ruby
# CORRECT: PDF uses extra_locals for template rendering
handle_pdf_export(
  ProductionServices::ExportPdfService,
  records,
  error_path: productions_path,
  extra_locals: {
    totals: records.sum(:total_bunches),
    filter_data: get_current_filters
  }
)
```

## Implementation Details

### BaseExporter

Stores all options passed via `**options`:

```ruby
class BaseExporter
  def initialize(records:, params: {}, **options)
    @options = options  # Stores extra_locals and other options
  end
end
```

### CsvExporter

**Ignores** `extra_locals` - not used anywhere:

```ruby
class CsvExporter < BaseExporter
  # extra_locals parameter is NOT extracted or used
  # Template rendering is not applicable to plain text CSV
end
```

### PdfExporter

**Extracts and uses** `extra_locals` for template rendering:

```ruby
class PdfExporter < BaseExporter
  def initialize(records:, params: {}, view_context:, extra_locals: {})
    super(records: records, params: params)
    @extra_locals = extra_locals
  end

  private

  def template_locals
    @extra_locals  # Passed to view context
  end
end
```

## Real World Example

### Productions Export

Controller passes different data based on export format:

```ruby
def export_csv
  records = @q.result.ordered

  # CSV doesn't need pre-calculated totals for template
  # Service will generate its own row data
  handle_csv_export(
    ProductionServices::ExportCsvService,
    records,
    error_path: productions_path
  )
end

def export_pdf
  records = @q.result.ordered

  # PDF needs pre-calculated totals for display in template
  totals = {
    total_bunches: records.sum(:total_bunches),
    total_weight_ton: records.sum(:total_weight_ton)
  }

  filter_data = {
    mill: get_selected_mill,
    block: get_selected_block
  }

  handle_pdf_export(
    ProductionServices::ExportPdfService,
    records,
    error_path: productions_path,
    extra_locals: { totals: totals, filter_data: filter_data }
  )
end
```

## Future Export Types

If you add new export formats (Excel, JSON, etc.), consider:

| Format | Template? | extra_locals? | Reason                   |
| ------ | --------- | ------------- | ------------------------ |
| CSV    | No        | ❌ No         | Plain text, no rendering |
| PDF    | Yes       | ✅ Yes        | HTML template rendering  |
| Excel  | Maybe     | Varies        | Depends on complexity    |
| JSON   | No        | ❌ No         | Structured data format   |

## Testing extra_locals

### CSV Tests - Don't Check extra_locals

```ruby
def test_csv_export_ignores_extra_locals
  exporter = ExportCsvService.new(
    records: productions,
    extra_locals: { totals: { bunches: 9999 } }
  )

  result = exporter.call
  # extra_locals is not used or validated
  # Just verify CSV structure
  assert_includes(result.value![:data], 'CSV headers')
end
```

### PDF Tests - Verify extra_locals Used

```ruby
def test_pdf_export_uses_extra_locals
  exporter = ExportPdfService.new(
    records: productions,
    view_context: view_context,
    extra_locals: { totals: { bunches: 100 } }
  )

  result = exporter.call
  pdf_data = result.value![:data]

  # Verify extra_locals were included in PDF
  assert_includes(pdf_data, '100')  # totals value in PDF
end
```

## Documentation Cross-References

- [ExportHandling Concern](../app/controllers/concerns/export_handling.rb) - Detailed parameter docs
- [CsvExporter](../app/services/exporters/csv_exporter.rb) - CSV implementation
- [PdfExporter](../app/services/exporters/pdf_exporter.rb) - PDF implementation with extra_locals usage
- [ProductionsController](../app/controllers/productions_controller.rb) - Real usage example
- [Export Services Guide](./EXPORT_SERVICES_GUIDE.md) - General export system guide
