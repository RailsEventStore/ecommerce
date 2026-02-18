import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static targets = ["column"]
  static values = { pipelineId: String }

  connect() {
    this.columnTargets.forEach((column) => {
      Sortable.create(column, {
        group: "deals",
        animation: 150,
        onEnd: this.onEnd.bind(this)
      })
    })
  }

  onEnd(event) {
    const dealId = event.item.dataset.dealId
    const stage = event.to.dataset.stage
    const csrfToken = document.querySelector('meta[name="csrf-token"]').content

    fetch(`/pipelines/${this.pipelineIdValue}/move_deal`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "X-CSRF-Token": csrfToken
      },
      body: `deal_id=${encodeURIComponent(dealId)}&stage=${encodeURIComponent(stage)}`
    })
  }
}
