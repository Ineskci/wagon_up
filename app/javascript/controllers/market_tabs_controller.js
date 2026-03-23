import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    this.showTab(0)
  }

  select(event) {
    const index = this.tabTargets.indexOf(event.currentTarget)
    this.showTab(index)
  }

  showTab(index) {
    this.tabTargets.forEach((tab, i) => {
      const active = i === index
      tab.setAttribute("data-active", active)
      tab.style.borderBottomColor = active ? "var(--brand)" : "transparent"
      tab.style.color = active ? "var(--brand)" : "var(--ink-3)"
      tab.style.fontWeight = active ? "700" : "500"
    })
    this.panelTargets.forEach((panel, i) => {
      panel.hidden = i !== index
    })
  }
}
