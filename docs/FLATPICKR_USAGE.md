# Flatpickr Date Picker Usage Guide

## Overview

The Flatpickr Stimulus controller provides a reusable, feature-rich date and time picker for your Rails application. It integrates seamlessly with Ransack for search forms and supports multiple date selection modes.

## Features

- ✅ Single date selection
- ✅ Multiple date selection
- ✅ Date range selection
- ✅ Time picker support
- ✅ Automatic Ransack integration for search forms
- ✅ Persists selected dates after page reload
- ✅ Customizable date formats
- ✅ Mobile-friendly

## Installation

The Flatpickr controller is already installed and configured in this project:

```ruby
# config/importmap.rb
pin "flatpickr" # @4.6.13
```

```erb
<!-- app/views/layouts/dashboard/application.html.erb -->
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr@4.6.13/dist/flatpickr.min.css">
```

## Basic Usage

### 1. Simple Date Picker

For a basic single date selector:

```erb
<input type="text"
       class="form-control"
       placeholder="Select a date"
       data-controller="flatpickr"
       data-flatpickr-date-format-value="d-m-Y">
```

**Configuration:**

- `data-controller="flatpickr"` - Activates the controller
- `data-flatpickr-date-format-value="d-m-Y"` - Sets display format (e.g., 15-03-2025)

### 2. Date Picker with Time

To include time selection:

```erb
<input type="text"
       class="form-control"
       placeholder="Select date and time"
       data-controller="flatpickr"
       data-flatpickr-enable-time-value="true"
       data-flatpickr-date-format-value="d-m-Y H:i">
```

**Configuration:**

- `data-flatpickr-enable-time-value="true"` - Enables time picker
- `H:i` in format - Shows hour:minute (24-hour format)

### 3. Date Range Picker (Standalone)

For selecting a date range without Ransack:

```erb
<input type="text"
       class="form-control"
       placeholder="Select date range"
       data-controller="flatpickr"
       data-flatpickr-mode-value="range"
       data-flatpickr-date-format-value="d-m-Y">
```

**Configuration:**

- `data-flatpickr-mode-value="range"` - Enables range selection mode

## Ransack Integration

### Date Range Filter for Search Forms

The most common use case is filtering records by date range in search forms:

```erb
<%= search_form_for @q, url: workers_path do |f| %>
  <div class="form-group">
    <label>Hired Date Range</label>

    <!-- Visible input for date picker -->
    <input type="text"
           class="form-control"
           placeholder="Select Date Range"
           data-controller="flatpickr"
           data-flatpickr-mode-value="range"
           data-flatpickr-date-format-value="d-m-Y"
           data-flatpickr-field-name-value="q[hired_date]">

    <!-- Hidden fields for Ransack -->
    <%= f.hidden_field :hired_date_gteq, value: params.dig(:q, :hired_date_gteq) %>
    <%= f.hidden_field :hired_date_lteq, value: params.dig(:q, :hired_date_lteq) %>
  </div>

  <%= f.submit 'Search', class: 'btn btn-primary' %>
<% end %>
```

**How it works:**

1. User clicks the input field
2. Flatpickr calendar opens
3. User selects start and end dates
4. Controller automatically populates hidden fields with `YYYY-MM-DD` format
5. User clicks "Search" button
6. Form submits with `q[hired_date_gteq]` and `q[hired_date_lteq]` parameters
7. Ransack filters records accordingly

**Important Notes:**

- The `data-flatpickr-field-name-value` must match the base field name (e.g., `q[hired_date]`)
- Hidden fields must be named with `_gteq` and `_lteq` suffixes for Ransack
- Display format can be any valid Flatpickr format
- Backend always receives `YYYY-MM-DD` format regardless of display format

## Configuration Options

### Available Data Attributes

| Attribute                          | Type    | Default    | Description                                      |
| ---------------------------------- | ------- | ---------- | ------------------------------------------------ |
| `data-flatpickr-mode-value`        | String  | `"single"` | Selection mode: `single`, `multiple`, or `range` |
| `data-flatpickr-date-format-value` | String  | `"Y-m-d"`  | Display format for dates                         |
| `data-flatpickr-enable-time-value` | Boolean | `false`    | Enable time picker                               |
| `data-flatpickr-field-name-value`  | String  | `""`       | Base field name for Ransack integration          |

### Common Date Formats

| Format        | Example             | Description                  |
| ------------- | ------------------- | ---------------------------- |
| `d-m-Y`       | 15-03-2025          | Day-Month-Year (European)    |
| `m/d/Y`       | 03/15/2025          | Month/Day/Year (American)    |
| `Y-m-d`       | 2025-03-15          | Year-Month-Day (ISO)         |
| `d M Y`       | 15 Mar 2025         | Day Month Year (Short month) |
| `d F Y`       | 15 March 2025       | Day Month Year (Full month)  |
| `d-m-Y H:i`   | 15-03-2025 14:30    | Date with time (24h)         |
| `d-m-Y h:i K` | 15-03-2025 02:30 PM | Date with time (12h)         |

See [Flatpickr formatting documentation](https://flatpickr.js.org/formatting/) for more options.

## Real-World Examples

### Example 1: Worker Hired Date Filter

```erb
<!-- app/views/workers/index.html.erb -->
<%= search_form_for @q, url: workers_path do |f| %>
  <table class="table">
    <thead>
      <tr>
        <th>Hired Date</th>
        <!-- other headers -->
      </tr>
      <tr>
        <th>
          <input type="text"
                 class="form-control form-control-sm"
                 placeholder="Select Date Range"
                 data-controller="flatpickr"
                 data-flatpickr-mode-value="range"
                 data-flatpickr-date-format-value="d-m-Y"
                 data-flatpickr-field-name-value="q[hired_date]">
          <%= f.hidden_field :hired_date_gteq, value: params.dig(:q, :hired_date_gteq) %>
          <%= f.hidden_field :hired_date_lteq, value: params.dig(:q, :hired_date_lteq) %>
        </th>
        <!-- other filters -->
      </tr>
    </thead>
  </table>

  <%= f.submit 'Search' %>
<% end %>
```

### Example 2: Order Created Date Filter

```erb
<!-- app/views/work_order/details/index.html.erb -->
<%= search_form_for @q, url: work_order_details_path do |f| %>
  <div class="row">
    <div class="col-md-4">
      <label>Order Date</label>
      <input type="text"
             class="form-control"
             placeholder="Select Date Range"
             data-controller="flatpickr"
             data-flatpickr-mode-value="range"
             data-flatpickr-date-format-value="d-m-Y"
             data-flatpickr-field-name-value="q[created_at]">
      <%= f.hidden_field :created_at_gteq %>
      <%= f.hidden_field :created_at_lteq %>
    </div>
  </div>

  <%= f.submit 'Filter', class: 'btn btn-primary' %>
<% end %>
```

### Example 3: Single Date Field (Form Input)

```erb
<!-- app/views/workers/new.html.erb -->
<%= form_with model: @worker do |f| %>
  <div class="form-group">
    <%= f.label :hired_date, "Hired Date" %>
    <%= f.text_field :hired_date,
        class: "form-control",
        placeholder: "Select date",
        data: {
          controller: "flatpickr",
          flatpickr_date_format_value: "d-m-Y"
        } %>
  </div>

  <%= f.submit "Save", class: "btn btn-success" %>
<% end %>
```

### Example 4: Event Scheduler with Time

```erb
<%= form_with model: @event do |f| %>
  <div class="form-group">
    <%= f.label :start_time, "Event Start Time" %>
    <%= f.text_field :start_time,
        class: "form-control",
        placeholder: "Select date and time",
        data: {
          controller: "flatpickr",
          flatpickr_enable_time_value: true,
          flatpickr_date_format_value: "d-m-Y H:i"
        } %>
  </div>

  <%= f.submit "Create Event", class: "btn btn-primary" %>
<% end %>
```

## Advanced Usage

### Custom Styling

You can add custom CSS classes to style the input:

```erb
<input type="text"
       class="form-control my-custom-class"
       data-controller="flatpickr"
       data-flatpickr-date-format-value="d-m-Y">
```

### Combining with Other Stimulus Controllers

```erb
<input type="text"
       class="form-control"
       data-controller="flatpickr search-form"
       data-flatpickr-mode-value="range"
       data-action="change->search-form#autoSubmit">
```

### Programmatic Access

If you need to access the Flatpickr instance from another controller:

```javascript
// In another Stimulus controller
this.flatpickrElement = this.element.querySelector(
  '[data-controller~="flatpickr"]'
);
this.flatpickrController =
  this.application.getControllerForElementAndIdentifier(
    this.flatpickrElement,
    "flatpickr"
  );

// Access the picker instance
this.flatpickrController.picker.setDate(new Date());
```

## Troubleshooting

### Calendar doesn't appear

**Problem:** Click on input but nothing happens  
**Solution:**

- Check browser console for JavaScript errors
- Verify Flatpickr CSS is loaded
- Ensure `data-controller="flatpickr"` is present
- Restart Docker if you just added the controller: `docker compose restart web`

### Date range filter not working

**Problem:** Selecting dates doesn't filter results  
**Solution:**

- Verify hidden field names match: `_gteq` and `_lteq` suffixes
- Check `data-flatpickr-field-name-value` matches base field name
- Ensure hidden fields are inside the form
- Check Ransack is configured to search that field:

```ruby
# app/models/worker.rb
def self.ransackable_attributes(_auth_object = nil)
  %w[id name hired_date created_at updated_at]
end
```

### Dates not persisting after page reload

**Problem:** Selected date range disappears after search  
**Solution:**

- Hidden fields must have `value: params.dig(:q, :field_name_gteq)` attribute
- Example: `<%= f.hidden_field :hired_date_gteq, value: params.dig(:q, :hired_date_gteq) %>`

### Wrong date format in database

**Problem:** Dates stored incorrectly  
**Solution:**

- Controller always sends `YYYY-MM-DD` to backend (correct format)
- Display format only affects what user sees
- Check your model/migration for correct date column type

## Best Practices

1. **Always use placeholder text** to guide users:

   ```erb
   placeholder="Select Date Range"
   ```

2. **Keep display format consistent** across your app:

   ```erb
   data-flatpickr-date-format-value="d-m-Y"
   ```

3. **Use descriptive field names** for Ransack:

   ```erb
   data-flatpickr-field-name-value="q[hired_date]"
   ```

4. **Include both hidden fields** for ranges:

   ```erb
   <%= f.hidden_field :hired_date_gteq %>
   <%= f.hidden_field :hired_date_lteq %>
   ```

5. **Add appropriate Bootstrap sizing classes**:

   ```erb
   class="form-control form-control-sm"  <!-- for table filters -->
   class="form-control"                  <!-- for regular forms -->
   ```

6. **Don't auto-submit forms** - let users click Search button for better UX

## Related Documentation

- [Flatpickr Official Docs](https://flatpickr.js.org/)
- [Ransack Documentation](https://github.com/activerecord-hackery/ransack)
- [Stimulus Handbook](https://stimulus.hotwired.dev/)
- [STIMULUS_TURBO_GUIDE.md](STIMULUS_TURBO_GUIDE.md) - Our Stimulus/Turbo guide

## Support

For issues or questions about the Flatpickr controller:

1. Check this documentation first
2. Review the controller code: `app/javascript/controllers/flatpickr_controller.js`
3. Check browser console for errors
4. Ask the development team

---

**Last Updated:** November 10, 2025  
**Version:** 1.0.0  
**Flatpickr Version:** 4.6.13
