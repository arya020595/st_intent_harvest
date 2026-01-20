# Parameter Whitelisting Security Guide

## Overview

This guide explains how to safely handle user-provided parameters in Rails applications, specifically addressing the security risks of `.to_unsafe_h` and implementing proper parameter whitelisting.

## The Problem: .to_unsafe_h

### What's Unsafe About .to_unsafe_h?

The `.to_unsafe_h` method converts ActionController parameters to a hash without any filtering:

```ruby
# VULNERABLE: Accepts ANY parameter without validation
params[:q].to_unsafe_h
# => { date_gteq: "2024-01-01", date_lteq: "2024-12-31", malicious_key: "bad_value" }
```

**Risks:**
- 🔴 Allows **mass assignment** of unexpected attributes
- 🔴 Can bypass Rails parameter whitelisting
- 🔴 Enables injection of parameters not intended by the developer
- 🔴 Opens door to **privilege escalation** if unintended attributes are assignable

### Real-World Attack Example

```ruby
# User submits form with legitimate filters
q[date_gteq] = 2024-01-01
q[date_lteq] = 2024-12-31

# Attacker injects extra parameter
q[admin_role] = true  # ← Unexpected!

# With .to_unsafe_h, this becomes:
params[:q].to_unsafe_h
# => { date_gteq: "2024-01-01", ..., admin_role: "true" }
```

## The Solution: Parameter Whitelisting

### Whitelist Approach

Define **exactly which parameters** are allowed and reject everything else:

```ruby
# ✅ SECURE: Only whitelisted parameters accepted
ALLOWED_PRODUCTION_SEARCH_KEYS = {
  date_gteq: :string,
  date_lteq: :string,
  block_id_eq: :string,
  mill_id_eq: :string,
  s: :string  # Sort parameter
}.freeze
```

### Implementation

```ruby
def sanitized_ransack_params(allowed_keys = ALLOWED_PRODUCTION_SEARCH_KEYS)
  return {} unless params[:q].present?

  safe_params = {}
  params[:q].to_unsafe_h.each do |key, value|
    key_sym = key.to_sym
    if allowed_keys.key?(key_sym)
      safe_params[key_sym] = value
    else
      Rails.logger.warn("[Security] Skipped disallowed parameter: #{key}")
    end
  end

  safe_params
end
```

**How it works:**
1. Iterate through each parameter in the request
2. Check if key exists in whitelist
3. Only include whitelisted parameters
4. Log any rejected parameters for security monitoring

## Usage Examples

### ✅ Correct: Use Whitelisted Helper

```erb
<!-- In views: Export URLs with safe parameters -->
<% export_params[:q] = safe_export_params %>
<%= link_to productions_path(export_params), class: "btn btn-primary" %>
```

### ❌ Avoid: Direct .to_unsafe_h

```erb
<!-- VULNERABLE: Don't use this -->
<% export_params[:q] = params[:q].to_unsafe_h %>
<%= link_to productions_path(export_params) %>
```

### ✅ Correct: In Helpers

```ruby
def hidden_search_fields
  return '' unless params[:q]

  sanitized_ransack_params.map do |key, value|
    hidden_field_tag "q[#{key}]", value
  end.compact.join.html_safe
end
```

### ✅ Correct: Export URLs

```ruby
def export_csv
  records = @q.result.ordered
  
  handle_csv_export(
    ProductionServices::ExportCsvService,
    records,
    error_path: productions_path
  )
end
```

## Rails Built-in Strong Parameters

### Alternative: Use .permit (When Available)

If you're using Rails Strong Parameters in a controller:

```ruby
# In controller (more suitable location for parameter filtering)
def production_params
  params.require(:production).permit(:date, :block_id, :mill_id)
end
```

However, for **complex Ransack queries**, whitelisting in a helper is more practical:

```ruby
# Ransack query params are complex and dynamic
params[:q]  # => { date_gteq: "...", date_lteq: "...", s: "..." }

# Use helper-level whitelisting for query parameters
safe_export_params  # => Filtered with ALLOWED_PRODUCTION_SEARCH_KEYS
```

## Implementation in This Codebase

### Updated Components

**1. RansackMultiSortHelper** - New security methods:
```ruby
ALLOWED_PRODUCTION_SEARCH_KEYS = {
  date_gteq: :string,
  date_lteq: :string,
  block_id_eq: :string,
  mill_id_eq: :string,
  s: :string
}.freeze

def sanitized_ransack_params(allowed_keys = ALLOWED_PRODUCTION_SEARCH_KEYS)
  # ✅ Filters parameters using whitelist
end

def safe_export_params
  # ✅ Convenience wrapper for export URLs
end
```

**2. ProductionsController** - Views use helpers:
```erb
<% export_params[:q] = safe_export_params %>
<!-- ✅ Secure parameter passing -->
```

**3. Logging** - Rejected parameters are logged:
```
[Security] Skipped disallowed Ransack parameter: admin_role
```

## Extending to Other Filters

### Adding New Allowed Parameters

When adding new search filters, update the whitelist:

```ruby
ALLOWED_PRODUCTION_SEARCH_KEYS = {
  # ... existing keys ...
  worker_id_eq: :string,        # ← New filter
  status_eq: :string,            # ← New filter
}.freeze
```

### Testing Whitelist

```ruby
def test_sanitized_ransack_params_rejects_unexpected_keys
  allow(params).to receive(:[]).with(:q).and_return({
    'date_gteq' => '2024-01-01',
    'malicious_key' => 'bad_value'  # Should be rejected
  })

  result = helper.sanitized_ransack_params
  assert_equal({ date_gteq: '2024-01-01' }, result)
  assert_not_includes(result.keys, :malicious_key)
end
```

## Security Best Practices

### ✅ DO:
- ✅ Use `.permit()` in controllers for strong parameters
- ✅ Use whitelisting in views/helpers for dynamic params
- ✅ Log rejected parameters for security auditing
- ✅ Document allowed parameters clearly
- ✅ Review whitelist when adding new filters

### ❌ DON'T:
- ❌ Use `.to_unsafe_h` without validation
- ❌ Accept arbitrary parameters from users
- ❌ Assume Ransack alone prevents mass assignment
- ❌ Pass unvalidated params to exports
- ❌ Skip parameter validation "for now"

## Related Documentation

- [Rails Strong Parameters Guide](https://guides.rubyonrails.org/action_controller_overview.html#strong-parameters)
- [Ransack Documentation](https://activerecord-hackery.github.io/ransack/)
- [OWASP: Mass Assignment Protection](https://owasp.org/www-community/attacks/Mass_Assignment)
- [Export Services Guide](./EXPORT_SERVICES_GUIDE.md) - Export parameter handling
- [EXTRA_LOCALS_PARAMETER.md](./EXTRA_LOCALS_PARAMETER.md) - Export parameter documentation

## Monitoring & Auditing

### Log Monitoring

Search logs for rejected parameters:

```bash
# Check for attempted parameter injection
grep -i "Skipped disallowed Ransack parameter" log/production.log
```

### Metrics to Track

- Count of rejected parameters by type
- Frequency of injection attempts
- Source IP addresses attempting injection (for security incidents)

## Migration Path

If you have existing code using `.to_unsafe_h`:

### Step 1: Identify Usage
```bash
grep -r "to_unsafe_h" app/
```

### Step 2: Create Whitelist
```ruby
ALLOWED_KEYS = { ... }
```

### Step 3: Update References
```ruby
# Before
params[:q].to_unsafe_h

# After
sanitized_ransack_params(ALLOWED_KEYS)
```

### Step 4: Test
- Unit tests for whitelist filtering
- Integration tests for export functionality
- Security tests for injection attempts

## Conclusion

Parameter whitelisting is a critical security practice that prevents mass assignment vulnerabilities. By explicitly defining which parameters are allowed, you create a secure boundary between user input and your application logic.

**Remember:** Assume all user input is potentially malicious until proven otherwise.
