import flatpicker from "../vendor/flatpickr"
import { AsYouType } from "../vendor/libphonenumber-js.min"

let Hooks = {}

Hooks.Calendar = {
      mounted() {
        this.pickr = flatpicker(this.el, {
          inline: true,
          mode: "range",
          showMonths: 2,
          onChange: (selectedDates) => {
            if (selectedDates.length != 2) return;
            // this pushEvent is what pushes stuff to the livevie
            // its handled in liveview by the handle_event "dates_picked" function
            this.pushEvent("dates-picked", selectedDates)
          }
        })
        this.handleEvent("add-unavailable-dates", (dates) => {
          this.pickr.set("disable", [dates, ...this.pickr.config.disable])
        })
        // push event to liveview to ask for unavailable dates
        this.pushEvent("unavailable-dates", {}, (reply, ref) => {
          this.pickr.set("disable", reply.dates)
        })
    },
      destroyed () {
      this.pickr.destroy()
    }
}


Hooks.PhoneNumber = {
  mounted() {
    this.el.addEventListener("input", e => {
      this.el.value = new AsYouType("US").input(this.el.value)
    })
  }
}

export default Hooks;