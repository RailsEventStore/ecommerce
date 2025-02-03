// app/javascript/controllers/timezone_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  connect() {
    this.detectAndSetTimezone()
  }

  detectAndSetTimezone() {
    const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone

    document.cookie = `timezone=${timezone}`
  }
}
