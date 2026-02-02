# 🚀 AppPlanner

A premium project specification and roadmap management tool built with Elixir & Phoenix. Plan, track, and export your project documentation with ease.

### ✨ Key Features
- **Project Hierarchy**: Manage main projects and nested sub-components.
- **Markdown Support**: Rich text rendering for descriptions, rationale, and technical strategies.
- **Master Export**: Generate professional PDF documentation for stakeholders.
- **Custom Metadata**: Tailor meta data for every project and feature.

---

### 💻 Local Development

1. **Setup Environment**:
   ```bash
   cp .env.example .env
   # Update .env with your local credentials
   ```

2. **Install & Setup**:
   ```bash
   mix setup
   ```

3. **Run Server**:
   ```bash
   mix phx.server
   # Visit localhost:4006
   ```

---

### 🌐 Deployment (Gigalixir)

Follow these steps to deploy your instance to Gigalixir:

1. **Create App**:
   ```bash
   gigalixir create -n your-app-name
   ```

2. **Provision Database**:
   ```bash
   gigalixir pg:create --free
   ```

3. **Configure Secrets**:
   ```bash
   gigalixir config:set SECRET_KEY_BASE=$(mix phx.gen.secret)
   gigalixir config:set PHX_HOST=your-app-name.gigalixirapp.com
   ```

4. **Deploy Code**:
   ```bash
   git push gigalixir main
   ```

5. **Run Migrations**:
   ```bash
   gigalixir run mix ecto.migrate
   ```

---
*Built with ❤️ using Phoenix & LiveView.*
