# Documentation Index

Comprehensive documentation for the ST Intent Harvest application, organized by context.

---

## 📁 Directory Structure

```
docs/
├── getting-started/          # 🚀 Onboarding & Quick Start
├── development/              # 💻 Development Workflow
│   └── git/                  # Git-related guides
├── architecture/             # 🏗️ Design Patterns & SOLID
├── authentication/           # 🔐 User Authentication (Devise)
├── authorization/            # 🛡️ Permissions & Access Control
├── security/                 # 🔒 Security Best Practices
├── database/                 # 🗄️ Models, Queries & Auditing
│   └── ransack/              # Search & filtering
├── frontend/                 # 🎨 UI, Stimulus & Turbo
├── features/                 # ⚙️ Feature Implementations
│   ├── work-orders/          # Work order functionality
│   └── payroll/              # Pay calculation & deductions
├── import-export/            # 📤 Import & Export Services
├── devops/                   # 🐳 Docker, Nginx & Deployment
├── testing/                  # ✅ TDD & Testing Guides
├── logging/                  # 📝 Application Logging
├── performance/              # ⚡ Optimization Guides
└── troubleshooting/          # 🔧 Common Issues & Solutions
```

---

## 📚 Quick Navigation

### 🚀 Getting Started

| Document                                                           | Description                |
| ------------------------------------------------------------------ | -------------------------- |
| [QUICK_START.md](getting-started/QUICK_START.md)                   | Get up and running quickly |
| [TEAM_SETUP_CHECKLIST.md](getting-started/TEAM_SETUP_CHECKLIST.md) | New team member onboarding |

### 💻 Development

| Document                                                                   | Description                      |
| -------------------------------------------------------------------------- | -------------------------------- |
| [RAILS_DEVELOPMENT_WORKFLOW.md](development/RAILS_DEVELOPMENT_WORKFLOW.md) | Rails development best practices |
| [RUBOCOP_AUTO_FORMAT_GUIDE.md](development/RUBOCOP_AUTO_FORMAT_GUIDE.md)   | Code formatting & linting        |
| [COMMIT_INSTRUCTIONS.md](development/git/COMMIT_INSTRUCTIONS.md)           | Commit message conventions       |
| [GIT_BRANCHING_STRATEGY.md](development/git/GIT_BRANCHING_STRATEGY.md)     | Branch naming & workflow         |
| [GIT_HOOKS_GUIDE.md](development/git/GIT_HOOKS_GUIDE.md)                   | Pre-commit hooks setup           |

### 🏗️ Architecture

| Document                                                                        | Description                  |
| ------------------------------------------------------------------------------- | ---------------------------- |
| [AASM_ERROR_HANDLING_GUIDE.md](architecture/AASM_ERROR_HANDLING_GUIDE.md)       | State machine error handling |
| [DENORMALIZABLE_USAGE_GUIDE.md](architecture/DENORMALIZABLE_USAGE_GUIDE.md)     | Denormalization concern      |
| [RESPONSE_HANDLING_JSON_USAGE.md](architecture/RESPONSE_HANDLING_JSON_USAGE.md) | JSON response patterns       |
| [WORK_ORDER_SOLID_REFACTORING.md](architecture/WORK_ORDER_SOLID_REFACTORING.md) | SOLID principles applied     |

### 🔐 Authentication

| Document                                                                                    | Description                  |
| ------------------------------------------------------------------------------------------- | ---------------------------- |
| [DEVISE_GUIDE.md](authentication/DEVISE_GUIDE.md)                                           | Devise configuration & usage |
| [CURRENT_USER_VS_CURRENT_ATTRIBUTE.md](authentication/CURRENT_USER_VS_CURRENT_ATTRIBUTE.md) | Current user patterns        |

### 🛡️ Authorization

| Document                                                                                   | Description                |
| ------------------------------------------------------------------------------------------ | -------------------------- |
| [PERMISSIONS_README.md](authorization/PERMISSIONS_README.md)                               | Permission system overview |
| [PERMISSION_QUICK_START.md](authorization/PERMISSION_QUICK_START.md)                       | Quick permission setup     |
| [PERMISSION_SYSTEM_GUIDE.md](authorization/PERMISSION_SYSTEM_GUIDE.md)                     | Complete permission guide  |
| [PERMISSION_REFERENCE.md](authorization/PERMISSION_REFERENCE.md)                           | Permission reference       |
| [PERMISSION_MAPPING_GUIDE.md](authorization/PERMISSION_MAPPING_GUIDE.md)                   | Permission mapping         |
| [PERMISSION_IMPLEMENTATION_SUMMARY.md](authorization/PERMISSION_IMPLEMENTATION_SUMMARY.md) | Implementation summary     |

### � Security

| Document                                                               | Description                        |
| ---------------------------------------------------------------------- | ---------------------------------- |
| [PARAMETER_WHITELISTING_GUIDE.md](security/PARAMETER_WHITELISTING_GUIDE.md) | Secure parameter handling          |

### �🗄️ Database

| Document                                                                      | Description                     |
| ----------------------------------------------------------------------------- | ------------------------------- |
| [AI_DATABASE_QUERY_INTEGRATION.md](database/AI_DATABASE_QUERY_INTEGRATION.md) | AI-powered database queries     |
| [AUDITED_USAGE.md](database/AUDITED_USAGE.md)                                 | Audit trail implementation      |
| [AUDITED_TESTING.md](database/AUDITED_TESTING.md)                             | Testing audited models          |
| [SOFT_DELETE_GUIDE.md](database/SOFT_DELETE_GUIDE.md)                         | Soft delete pattern             |
| [RANSACK_GUIDE.md](database/ransack/RANSACK_GUIDE.md)                         | Search & filtering with Ransack |
| [MULTI_SORT_IMPLEMENTATION.md](database/ransack/MULTI_SORT_IMPLEMENTATION.md) | Multi-column sorting            |

### 🎨 Frontend

| Document                                                            | Description                  |
| ------------------------------------------------------------------- | ---------------------------- |
| [STIMULUS_TURBO_GUIDE.md](frontend/STIMULUS_TURBO_GUIDE.md)         | Hotwire (Stimulus & Turbo)   |
| [MODAL_SYSTEM_GUIDE_EN.md](frontend/MODAL_SYSTEM_GUIDE_EN.md)       | Modal dialogs implementation |
| [FLATPICKR_USAGE.md](frontend/FLATPICKR_USAGE.md)                   | Date picker usage            |
| [LAYOUT_IMPLEMENTATION.md](frontend/LAYOUT_IMPLEMENTATION.md)       | Layout & styling             |
| [URL_MANAGEMENT_GUIDE_EN.md](frontend/URL_MANAGEMENT_GUIDE_EN.md)   | URL state management         |
| [PANDUAN_MANAJEMEN_URL_ID.md](frontend/PANDUAN_MANAJEMEN_URL_ID.md) | URL management (Indonesian)  |

### ⚙️ Features

#### Work Orders

| Document                                                                                    | Description          |
| ------------------------------------------------------------------------------------------- | -------------------- |
| [WORK_ORDER_FORM_IMPLEMENTATION.md](features/work-orders/WORK_ORDER_FORM_IMPLEMENTATION.md) | Work order forms     |
| [WORK_ORDER_STATUS_FLOW.md](features/work-orders/WORK_ORDER_STATUS_FLOW.md)                 | Status workflow      |
| [INVENTORY_IMPLEMENTATION.md](features/work-orders/INVENTORY_IMPLEMENTATION.md)             | Inventory management |

#### Payroll

| Document                                                                                          | Description                |
| ------------------------------------------------------------------------------------------------- | -------------------------- |
| [PAY_CALCULATION_GUIDE.md](features/payroll/PAY_CALCULATION_GUIDE.md)                             | Pay calculation system     |
| [PAY_CALCULATION_WORK_ORDER_DELETION.md](features/payroll/PAY_CALCULATION_WORK_ORDER_DELETION.md) | Work order deletion impact |
| [DEDUCTION_WAGE_RANGE_GUIDE.md](features/payroll/DEDUCTION_WAGE_RANGE_GUIDE.md)                   | Wage range deductions      |

### 📤 Import & Export

| Document                                                                           | Description                      |
| ---------------------------------------------------------------------------------- | -------------------------------- |
| [EXPORT_SERVICES_GUIDE.md](import-export/EXPORT_SERVICES_GUIDE.md)                 | CSV & PDF export architecture    |
| [EXTRA_LOCALS_PARAMETER.md](export-system/EXTRA_LOCALS_PARAMETER.md)               | extra_locals parameter guide     |
| [BLOCKS_IMPORT_GUIDE.md](import-export/BLOCKS_IMPORT_GUIDE.md)                     | Blocks import                    |
| [DEDUCTION_IMPORT_GUIDE.md](import-export/DEDUCTION_IMPORT_GUIDE.md)               | Deduction import                 |
| [DEDUCTION_IMPORT_QUICK_REF.md](import-export/DEDUCTION_IMPORT_QUICK_REF.md)       | Deduction import quick reference |
| [WORK_ORDER_RATES_IMPORT_GUIDE.md](import-export/WORK_ORDER_RATES_IMPORT_GUIDE.md) | Work order rates import          |

### 🐳 DevOps

| Document                                                                | Description              |
| ----------------------------------------------------------------------- | ------------------------ |
| [DOCKER_SETUP.md](devops/DOCKER_SETUP.md)                               | Docker environment setup |
| [DOCKER_GUIDE.md](devops/DOCKER_GUIDE.md)                               | Docker usage guide       |
| [DOCKER_COMPOSE_EXPLAINED.md](devops/DOCKER_COMPOSE_EXPLAINED.md)       | Docker Compose explained |
| [NGINX_SETUP_GUIDE.md](devops/NGINX_SETUP_GUIDE.md)                     | Nginx configuration      |
| [PRODUCTION_DEPLOYMENT_GUIDE.md](devops/PRODUCTION_DEPLOYMENT_GUIDE.md) | Production deployment    |

### ✅ Testing

| Document                                                     | Description                  |
| ------------------------------------------------------------ | ---------------------------- |
| [TDD_AND_TESTING_GUIDE.md](testing/TDD_AND_TESTING_GUIDE.md) | TDD & testing best practices |

### 📝 Logging

| Document                                                 | Description         |
| -------------------------------------------------------- | ------------------- |
| [APP_LOGGER_GUIDE.md](logging/APP_LOGGER_GUIDE.md)       | Application logging |
| [LOGGING_QUICK_START.md](logging/LOGGING_QUICK_START.md) | Quick logging setup |

### ⚡ Performance

| Document                                                                             | Description             |
| ------------------------------------------------------------------------------------ | ----------------------- |
| [PAGINATION_PERFORMANCE_ANALYSIS.md](performance/PAGINATION_PERFORMANCE_ANALYSIS.md) | Pagination optimization |
| [IMAGE_OPTIMIZATION_GUIDE.md](performance/IMAGE_OPTIMIZATION_GUIDE.md)               | Image optimization      |

### 🔧 Troubleshooting

| Document                                                 | Description               |
| -------------------------------------------------------- | ------------------------- |
| [TROUBLESHOOTING.md](troubleshooting/TROUBLESHOOTING.md) | Common issues & solutions |

---

## 🔍 Finding Documentation

1. **New to the project?** Start with [QUICK_START.md](getting-started/QUICK_START.md)
2. **Setting up development?** Check [DOCKER_SETUP.md](devops/DOCKER_SETUP.md)
3. **Adding a feature?** Review relevant guides in `features/` or `architecture/`
4. **Debugging issues?** See [TROUBLESHOOTING.md](troubleshooting/TROUBLESHOOTING.md)

---

_Last updated: January 20, 2026_
