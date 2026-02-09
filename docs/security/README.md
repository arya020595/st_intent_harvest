# Security Documentation

This directory contains security-related documentation for the ST Intent Harvest application, including best practices, vulnerability prevention, and security implementation guides.

## 📚 Available Guides

### Parameter Security

- **[PARAMETER_WHITELISTING_GUIDE.md](PARAMETER_WHITELISTING_GUIDE.md)** - Secure parameter handling, preventing mass assignment attacks

## Key Security Topics

### Parameter Whitelisting
Learn how to safely handle user-provided parameters using whitelist-based filtering instead of `.to_unsafe_h`:

- ✅ Define allowed parameters explicitly
- ✅ Reject unexpected parameters
- ✅ Log security events
- ✅ Prevent mass assignment vulnerabilities

See [PARAMETER_WHITELISTING_GUIDE.md](PARAMETER_WHITELISTING_GUIDE.md) for implementation details.

## Security Principles

1. **Least Privilege** - Only allow necessary parameters
2. **Whitelist Over Blacklist** - Explicitly allow, then reject everything else
3. **Fail Secure** - Default to secure, require explicit opt-in for features
4. **Defense in Depth** - Multiple layers of security checks
5. **Audit & Monitor** - Log security events and monitor for attacks

## Related Documentation

- [Rails Security Guide](https://guides.rubyonrails.org/security.html)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- Authorization System: [../authorization/](../authorization/)
- Authentication System: [../authentication/](../authentication/)
