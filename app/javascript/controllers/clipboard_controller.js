import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "toast"]

  copy() {
    const text = this.sourceTarget.innerText
    navigator.clipboard.writeText(text).then(() => {
      this.showToast()
    })
  }

  showToast() {
    const toast = document.getElementById("clipboard-toast")
    toast.classList.add("clipboard-toast--visible")
    setTimeout(() => toast.classList.remove("clipboard-toast--visible"), 2500)
  }
}
