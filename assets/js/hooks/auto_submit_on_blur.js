// Hook to auto-submit a form when an input loses focus
const AutoSubmitOnBlur = {
    mounted() {
        this.el.addEventListener('blur', () => {
            const formId = this.el.dataset.formId
            if (formId) {
                const form = document.getElementById(formId)
                if (form) {
                    // Trigger form submission
                    form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))
                }
            }
        })
    }
}

export default AutoSubmitOnBlur
