const $ = window.$

export default {

  initControls(container) {
    this.isPaused = false
    this.renderControls(container)
    this.registerClickEvents()
    return this
  },

  renderControls(container) {
    this.playBtn = $("<button>").addClass("mdl-button mdl-button--colored btn-anim").html('▶')
    this.pauseBtn = $("<button>").addClass("mdl-button mdl-button--colored btn-pause btn-anim").html('||')
    this.replayBtn = $("<button>").addClass("mdl-button mdl-button--colored btn-replay btn-anim").html('⟳')
      
    let buttons = $("<div>").addClass('anim-buttons').append(this.playBtn).append(this.pauseBtn).append(this.replayBtn)
    let parent = $("<div>").addClass('anim-control').append(buttons)
    $(container).append(parent)
    return this
  },

  registerClickEvents() {

    var self = this
    this.playBtn.click(() => {
      self.playBtn.hide()
      self.pauseBtn.show()
      self.isPaused = false
      self.play()

    })

    this.pauseBtn.click(() => {
      self.pauseBtn.hide()
      self.playBtn.show()
      self.isPaused = true
      self.pause()
    })

    this.replayBtn.click(() => {
      self.replayBtn.hide()
      self.pauseBtn.show()
      self.isPaused = false
      self.reset()
      self.play()
    })
  },

  showReplayButton() {
    this.pauseBtn.hide()
    this.replayBtn.show()
  }


}