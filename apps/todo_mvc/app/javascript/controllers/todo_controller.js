import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["label", "edit", "li"]

  startEditing() {
    this.liTarget.classList.add("editing")
    this.editTarget.value = this.labelTarget.textContent.trim()
    this.editTarget.focus()
    this.editTarget.select()
  }

  save(event) {
    if (event.type === "blur" || (event.type === "keydown" && event.key === "Enter")) {
      event.preventDefault()
      this.liTarget.classList.remove("editing")
      const form = this.editTarget.closest("form")
      if (form) {
        form.requestSubmit()
      }
    } else if (event.type === "keydown" && event.key === "Escape") {
      this.cancel()
    }
  }

  cancel() {
    this.liTarget.classList.remove("editing")
    this.editTarget.value = this.labelTarget.textContent.trim()
  }
}
