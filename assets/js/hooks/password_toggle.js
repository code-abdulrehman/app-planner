const PasswordToggle = {
  mounted() {
    this.inputSelector = this.el.dataset.passwordToggleInput || null
    this.buttonSelector = this.el.dataset.passwordToggleButton || null

    this.input = this.inputSelector ? this.el.querySelector(this.inputSelector) : null
    this.button = this.buttonSelector ? this.el.querySelector(this.buttonSelector) : null

    if (!this.input || !this.button) return

    this.updateUi()

    this.button.addEventListener("click", e => {
      e.preventDefault()
      const nextType = this.input.type === "password" ? "text" : "password"

      // Changing type can reset the cursor; preserve value + focus.
      const value = this.input.value
      const wasFocused = document.activeElement === this.input

      this.input.type = nextType
      this.input.value = value
      if (wasFocused) this.input.focus()

      this.updateUi()
    })
  },

  updateUi() {
    const isVisible = this.input.type === "text"
    this.button.setAttribute("aria-label", isVisible ? "Hide password" : "Show password")

    const showIcon = this.button.querySelector("[data-password-icon='show']")
    const hideIcon = this.button.querySelector("[data-password-icon='hide']")

    if (showIcon) showIcon.classList.toggle("hidden", isVisible)
    if (hideIcon) hideIcon.classList.toggle("hidden", !isVisible)
  }
}

export default PasswordToggle
