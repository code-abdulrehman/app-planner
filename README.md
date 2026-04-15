# 🚀 AppPlanner

A premium project specification and roadmap management tool built with Elixir & Phoenix. Plan, track, and export your project documentation with ease.

### ✨ Key Features
- **Project Hierarchy**: Manage main projects and nested sub-components.
- **Markdown Support**: Rich text rendering for descriptions, rationale, and technical strategies.
- **Master Export**: Generate professional PDF documentation for stakeholders.
- **Custom Metadata**: Tailor meta data for every project and feature.

---

### 💻 Local Development

1. **Setup environment variables**:
   ```bash
   cp .env.example .env
   # Update .env with your local credentials
   ```

2. **Install deps + setup DB**:
   ```bash
   mix setup
   ```

3. **Run server**:
   ```bash
   iex -S mix phx.server
   # Visit localhost:4006
   ```

4. **Run checks (recommended before pushing)**:
   ```bash
   mix precommit
   ```

---

### 🌐 Deployment (Gigalixir)

Follow these steps to deploy your instance to Gigalixir.

0. **Prereqs**:
   ```bash
   gigalixir login
   ```

1. **Create app**:
   ```bash
   gigalixir create -n your-app-name
   ```

2. **Provision database**:
   ```bash
   gigalixir pg:create --free
   ```

3. **Set required config**:
   ```bash
   gigalixir config:set SECRET_KEY_BASE="$(mix phx.gen.secret)"
   gigalixir config:set PHX_HOST="your-app-name.gigalixirapp.com"
   gigalixir config:set PHX_SERVER=true
   ```

4. **Add Gigalixir git remote (once)**:
   ```bash
   gigalixir git:remote your-app-name
   ```

5. **Deploy code**:
   ```bash
   git push gigalixir HEAD:main
   ```

6. **Run migrations**:
   ```bash
   gigalixir run mix ecto.migrate
   ```

---
*Built with ❤️ using Phoenix & LiveView.*
