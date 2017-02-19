import Vector from './vector'
import events1 from './centralized-events-1'
import events2 from './centralized-events-2'

import animationControlsMixin from './animation-controls-mixin'

const $ = window.$
const anime = window.anime
const events3 = window.events3

const colors = ['#3f51b5', '#ffc107', '#ff5722', '#795548', '#00BCD4', '#ff9800']

class TwoDViz {
  
  constructor({container,
               width, height,
               minX, maxX,
               minY, maxY,
               initialCoords, stagedInitialCoords,
               events, stagedEvents, eventsSampleFactor,
               showForcesAndArrows, showStage}) {
    this.el = container;
    this.width = width
    this.height = height
    this.minX = minX
    this.maxX = maxX
    this.minY = minY
    this.maxY = maxY
    this.showForcesAndArrows = showForcesAndArrows

    this.stagedInitialCoords = stagedInitialCoords
                               .map(coords => coords.map(c => this.toSVGCoord(c)))
    this.circles = new Array(initialCoords.length)

    this.events = events.map(e => {

      let forces = {}
      let totalForce = []
      let coords = []
      if (this.showForcesAndArrows) {
        forces = e.forces.map(f => {
          return {from: f.from, vector: this.toSVGCoord(f.vector)}
        })
        totalForce = this.toSVGCoord(Vector.add(e.x_i, e.totalForce))
        coords = e.coords.map(c => this.toSVGCoord(c))
      }

      return {
        i: e.i,
        x_i: this.toSVGCoord(e.x_i),
        x_i_next: this.toSVGCoord(e.x_i_next),
        totalForce,
        forces,
        coords,
        stage: e.stage
      }
    })
    
    this.eventsSampleFactor = eventsSampleFactor
    this.nextEventIndex = 0
    this.currentStage = -1
    this.coordsPerStage = stagedInitialCoords[0].length
    this.length = this.events.length

    for (let key of Object.keys(animationControlsMixin)) {
      this[key] = animationControlsMixin[key]
    }

    this.initControls(container)

    this.showStage = showStage
    if (showStage) {
      this.renderStage()
    }
    if (showForcesAndArrows) {
      this.renderLegend()
    }

  }

  renderLegend() {
    let parent = $(this.el).find('.anim-control')

    let items = [
      ['Individual Forces', '#F44336'],
      ['Total Force', '#FFEB3B'],
      ['Force Step', '#3f51b5']
    ]

    items.forEach(([label, color]) => {
      let item = $("<div>").addClass('legend-item')
                           .append($("<div>").addClass('legend-color').css('background', color))
                           .append($("<div>").html(label))
      parent.append(item)
    })
  }

  renderStage() {
    this.stageView = $("<div>").addClass('anim-stage').html("Stage 1")
    let parent = $(this.el).find('.anim-control')
    parent.append(this.stageView)
  }

  updateStageView(stage) {
    this.stageView.html("Stage " + (stage + 1))
  }

  reset() {
    this.nextEventIndex = 0
    this.currentStage = -1
    this.empty()
    this.render()
    return this
  }

  getNextEvent() {
    const event = this.events[this.nextEventIndex]
    this.nextEventIndex += this.eventsSampleFactor
    return event
  }

  async play() {
    
    while (this.nextEventIndex < (this.length - 4)) {
      if (this.isPaused) {
        return
      }
      const event = this.getNextEvent()
      if (event.stage !== this.currentStage) {
        if (event.stage < this.currentStage) {
          debugger
        }
        this.currentStage = event.stage
        this.updateStageView(this.currentStage)
        await this.moveCoordsToInitialPositions(this.currentStage)
        
      }
      await this.next(event)
    }
    this.showReplayButton()
  }

  pause() {
    this.isPaused = true
  }

  async next(event) {
    if (this.nextEventIndex % 100 === 0) {
      console.info('Event: ', this.nextEventIndex)
    }
    if (this.showForcesAndArrows) {
      const endPoints = event.forces.map(({from, vector}) => {
        return [event.x_i, event.coords[from]]
      })
      await this.drawLines(endPoints, {cls: 'force', stroke: '#F44336', showArrow: true})
      await this.drawLines([[event.x_i, event.totalForce]], {cls: 'force', stroke: '#FFEB3B', showArrow: true})
    }
    // await this.drawLines([[event.x_i, event.x_i_next]], {cls: 'force-step', stroke: colors[event.i % 4], showArrow: this.showForcesAndArrows})
    await this.movePoint(event.i, event.x_i_next)
    
    return new Promise((resolve, _reject) => {
      setTimeout(() => {
        if (this.showForcesAndArrows) {
          this.removeForces()
        }
        resolve(true)
      }, 10)
    })
  }

  removeForces() {
    $(this.el).find('.force').remove()
  }

  render() {
    this.initializeSvg()
    return this
  }

  empty() {
    this.svg.remove()
    if (this.showStage) {
      this.updateStageView(0)
    }
  }

  async moveCoordsToInitialPositions(stage) {
    let coords = this.stagedInitialCoords[stage]
    let promises = []
    let startIndex = stage * this.coordsPerStage
    for (let j = 0; j < this.coordsPerStage; j++) {
      let i = startIndex + j
      this.circles[i] = this.drawPointAt([0, 0], i)
      let p = this.movePoint(i, coords[j])
      promises.push(p)
      await this.delay(40)
    }
    return Promise.all(promises)
  }

  delay(t) {
    return new Promise((resolve, reject) => {
      setTimeout(() => resolve(), t)
    })
  }

  movePoint(index, [cx, cy]) {
    
    return new Promise((resolve, reject) => {
      let circle = this.circles[index]
      $(circle).animate(
        {cx, cy},
        {
          duration: 40,
          step: function(v1) {$(this).attr('cx', v1)},
          complete: function() {
            resolve(circle)
          }
        }
      )
    })
  }

  toSVGCoord(coord) {
    const [x, y] = coord

    const rangeX = (this.maxX - this.minX)
    const svgX = 5 + 0.97*(x-this.minX)*this.width/rangeX

    const rangeY = (this.maxY - this.minY)
    const svgY = 5 + 0.97*(this.maxY - y)*this.height/rangeY

    return [svgX, svgY]
  }

  drawPointAt([cx, cy], index) {
    const circle = this.createSvgEl('circle', {
      cx,
      cy,
      r: 3,
      fill: colors[index % 6]
    })
    this.svg.appendChild(circle)
    return circle
  }

  drawLines(endPoints, options) {
    let {cls, stroke, showArrow} = options
    return new Promise((resolve, _reject) => {
      let lines = []
      let targetProps = {}
      let currentProps = {}
      endPoints.forEach(([[x1, y1], [x2, y2]], i) => {
        let line = this.createSvgEl('line', {
            x1,
            y1,
            x2: x1,
            y2: y1,
            stroke,
            'class': cls,
            'stroke-width': 1,
            
        })
        if (showArrow) {
          line.setAttribute('marker-end', 'url(#Triangle)')
        }
        this.svg.appendChild(line)
        lines.push(line)

        currentProps[i * 2] = x1
        currentProps[i * 2 + 1] = y1
        targetProps[i * 2] = x2
        targetProps[i * 2 + 1] = y2
      })

      const lineCount = endPoints.length

      let animationProps = {
        duration: 20 * (this.length - this.nextEventIndex) / this.length,
        easing: 'easeOutQuad',
        update: function() {
          for (let i = 0; i < lineCount; i++) {
            let line = lines[i]
            line.setAttribute('x2', currentProps[i * 2])
            line.setAttribute('y2', currentProps[i * 2 + 1])
          }
        },
        complete: function() {
          resolve(true)
        }
      }

      anime(Object.assign({targets: currentProps},
                          targetProps,
                          animationProps))
    })
  }

  // svg stuff

  initializeSvg() {
    this.svg = this.createSvgEl('svg', {
        height: this.height,
        width: this.width
    });
    var defs = this.getTriangleMarkerDefinition();
    this.svg.appendChild(defs);
    this.el.appendChild(this.svg);
  }

  createSvgEl(type, attrs) {
    var el = document.createElementNS('http://www.w3.org/2000/svg', type);
    attrs = attrs || {};
    for (let key of Object.keys(attrs)) {
      el.setAttribute(key, attrs[key]);
    }
    return el;
  }

  getTriangleMarkerDefinition() {
    let marker = document.createElementNS('http://www.w3.org/2000/svg', 'marker')
    const markerAttrs = {
        'id': 'Triangle',
        'viewBox': '0 0 10 10',
        'refX': '0',
        'refY': '5',
        'markerWidth': '6',
        'markerHeight': '6',
        'orient': 'auto'
    }
    for (let key of Object.keys(markerAttrs)) {
      marker.setAttribute(key, markerAttrs[key])
    }

    let path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    path.setAttribute('d', 'M0,0 L10,5 L0,10 z');
    marker.appendChild(path);

    let defs = document.createElementNS('http://www.w3.org/2000/svg', 'defs')
    defs.appendChild(marker);
    return defs
  }

}

// Configure visualization objects

let initialCoords1 = [
  [0, 0],
  [4, 0],
  [10, 0],
  [7, 9]
]


let width = window.innerWidth * 0.7
let height = window.innerHeight * 0.8

// let twoD1 = new TwoDViz({
//   container: document.getElementById('two-d-viz-1'),
//   width,
//   height,
//   minX: -0.2,
//   maxX: 10.2,
//   minY: -0.2,
//   maxY: 9.2,
//   initialCoords: initialCoords1,
//   events: events1.events,
//   eventsSampleFactor: 1,
//   showForcesAndArrows: true,
//   showStage: false,
// })

// twoD1.render()

// let initialCoords2 = [
//   [0, 0],
//   [0, 0],
//   [0, 0],
//   [0, 0]
// ]

// let twoD2 = new TwoDViz({
//   container: document.getElementById('two-d-viz-2'),
//   width,
//   height,
//   minX: -4.3,
//   maxX: 5.2,
//   minY: -4,
//   maxY: 4.8,
//   initialCoords: initialCoords2,
//   events: events2.events,
//   eventsSampleFactor: 1,
//   showForcesAndArrows: false,
//   showStage: false,
// })

// twoD2.render()

events3.initial_coords = events3.initial_coords.map(c => c.slice(0, 2))
events3.staged_initial_coords = events3.staged_initial_coords.map(coords => coords.map(c => c.slice(0, 2)))
events3.events = events3.events.map(e => {
  e.forces = []
  e.totalForce = [0, 0]
  e.x_i = e.x_i.slice(0, 2)
  e.x_i_next = e.x_i_next.slice(0, 2)
  e.coords = []
  return e
})

let twoD3 = new TwoDViz({
  container: document.getElementById('two-d-viz-3'),
  width,
  height,
  minX: events3.min_x,
  maxX: events3.max_x,
  minY: events3.min_y,
  maxY: events3.max_y,
  initialCoords: events3.initial_coords,
  stagedInitialCoords: events3.staged_initial_coords,
  events: events3.events,
  stagedEvents: events3.staged_events,
  eventsSampleFactor: 3,
  showForcesAndArrows: false,
  showStage: true
})

twoD3.render()
window.t = twoD3

