# Team Development Setup Checklist

## ✅ New Team Member Onboarding

When a new developer joins the team, they should complete these steps:

### 1. Install Required Software

- [ ] Ruby 3.4.7 (check with `ruby -v`)
- [ ] PostgreSQL (for database)
- [ ] Git
- [ ] VS Code (recommended editor)
- [ ] Docker & Docker Compose (optional, for containerized dev)

### 2. Clone and Setup Repository

```bash
# Clone the repository
git clone <repository-url>
cd st_intent_harvest

# Install Ruby dependencies
bundle install

# Setup database
rails db:create db:migrate db:seed
```

### 3. Install VS Code Extensions

**Required Extensions** (VS Code will prompt you):

- RuboCop (`rubocop.vscode-rubocop`)
- Ruby LSP (`shopify.ruby-lsp`)

**Optional but Recommended**:

- EditorConfig (`EditorConfig.EditorConfig`)
- GitLens (`eamodio.gitlens`)
- Docker (`ms-azuretools.vscode-docker`)

To install quickly:

```bash
code --install-extension rubocop.vscode-rubocop
code --install-extension shopify.ruby-lsp
code --install-extension EditorConfig.EditorConfig
```

### 4. Verify Auto-Formatting Works

1. Open any Ruby file (e.g., `app/controllers/application_controller.rb`)
2. Add some poorly formatted code:
   ```ruby
   def test
         x=1
     return x
   end
   ```
3. Save the file (`Ctrl+S`)
4. **Expected**: Code should auto-format to proper style
5. If it doesn't work, see `.vscode/README.md` troubleshooting section

### 5. Run Tests

```bash
# Run all tests
rails test

# Run a specific test
rails test test/controllers/payslips_controller_test.rb
```

### 6. Start Development Server

```bash
# Standard Rails server
rails server

# Or using Docker
docker-compose up
```

Visit: http://localhost:3000

### 7. Run RuboCop Manually

```bash
# Check all files
bundle exec rubocop

# Auto-fix all files
bundle exec rubocop -a

# Check specific file
bundle exec rubocop app/controllers/payslips_controller.rb
```

### 8. Read Team Documentation

- [ ] `README.md` - Project overview
- [ ] `.vscode/README.md` - VS Code setup
- [ ] `docs/RUBOCOP_AUTO_FORMAT_GUIDE.md` - RuboCop usage
- [ ] `docs/RAILS_DEVELOPMENT_WORKFLOW.md` - Development workflow
- [ ] `docs/GIT_BRANCHING_STRATEGY.md` - Git workflow

## 🎯 Expected Behavior After Setup

### ✅ When you save a Ruby file:

- Auto-formats with RuboCop
- Removes trailing whitespace
- Adds final newline
- Fixes indentation
- Removes unused variables/code

### ✅ When you commit code:

- Code should already be formatted
- RuboCop violations should be minimal
- Tests should pass

### ✅ When you open the project:

- VS Code uses the team's settings automatically
- Extensions are recommended for installation
- EditorConfig applies consistent formatting

## 🚀 Daily Development Workflow

1. **Pull latest changes**

   ```bash
   git pull origin main
   bundle install  # If Gemfile changed
   rails db:migrate  # If migrations added
   ```

2. **Create feature branch**

   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Write code** (auto-formats on save!)

4. **Run tests**

   ```bash
   rails test
   ```

5. **Check RuboCop**

   ```bash
   bundle exec rubocop
   ```

6. **Commit and push**
   ```bash
   git add .
   git commit -m "Add your feature"
   git push origin feature/your-feature-name
   ```

## 🐛 Common Issues

### RuboCop not auto-formatting?

- Check extension is installed: `Ctrl+Shift+X` → search "RuboCop"
- Reload VS Code: `Ctrl+Shift+P` → "Reload Window"
- Check output: `Ctrl+Shift+U` → select "RuboCop"

### Bundle install fails?

- Check Ruby version: `ruby -v` (should be 3.4.7)
- Update bundler: `gem install bundler`
- Clear cache: `bundle clean --force`

### Database errors?

```bash
rails db:drop db:create db:migrate db:seed
```

## 📞 Need Help?

- Check `docs/TROUBLESHOOTING.md`
- Ask the team in Slack/Discord
- Review existing code for patterns

---

**Welcome to the team! 🎉**
