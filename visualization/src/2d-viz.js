import Vector from './vector'
import events1 from './centralized-events-1'
import events2 from './centralized-events-2'

import animationControlsMixin from './animation-controls-mixin'

const $ = window.$
const anime = window.anime


class TwoDViz {
  
  constructor({container,
               width, height,
               minX, maxX,
               minY, maxY,
               initialCoords, events, showForcesAndArrows}) {
    this.el = container;
    this.width = width
    this.height = height
    this.minX = minX
    this.maxX = maxX
    this.minY = minY
    this.maxY = maxY
    this.showForcesAndArrows = showForcesAndArrows

    this.initialCoords = initialCoords.map(c => this.toSVGCoord(c))

    this.events = events.map(e => {
      return {
        i: e.i,
        x_i: this.toSVGCoord(e.x_i),
        x_i_next: this.toSVGCoord(e.x_i_next),
        totalForce: this.toSVGCoord(Vector.add(e.x_i, e.totalForce)),
        forces: e.forces.map(f => {
          return {from: f.from, vector: this.toSVGCoord(f.vector)}
        }),
        coords: e.coords.map(c => this.toSVGCoord(c))
      }
    })
    
    this.nextEventIndex = 0
    this.length = this.events.length

    for (let key of Object.keys(animationControlsMixin)) {
      this[key] = animationControlsMixin[key]
    }

    this.initControls(container)

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

    // $(this.el).append(parent)
  }


  reset() {
    this.nextEventIndex = 0
    this.empty()
    this.render()
    return this
  }

  async play() {
    await this.moveCoordsToInitialPositions()
    while (this.nextEventIndex < this.length - 4) {
      if (this.isPaused) {
        return
      }
      await this.next()
    }
    this.showReplayButton()
  }

  pause() {
    this.isPaused = true
  }

  async next() {
    const colors = ['#3f51b5', '#ffc107', '#ff5722', '#795548']
    const event = this.events[this.nextEventIndex++]
    const endPoints = event.forces.map(({from, vector}) => {
      return [event.x_i, event.coords[from]]
    })
    if (this.showForcesAndArrows) {
      await this.drawLines(endPoints, {cls: 'force', stroke: '#F44336', showArrow: true})
      await this.drawLines([[event.x_i, event.totalForce]], {cls: 'force', stroke: '#FFEB3B', showArrow: true})
    }
    await this.drawLines([[event.x_i, event.x_i_next]], {cls: 'force-step', stroke: colors[event.i], showArrow: this.showForcesAndArrows})
    await this.movePoint(event.i, event.x_i_next)
    
    return new Promise((resolve, _reject) => {
      this.removeForces()
      setTimeout(() => {
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
  }

  async moveCoordsToInitialPositions() {
    this.circles = new Array(this.initialCoords.length)
    let promises = []
    for (let i = 0; i < this.initialCoords.length; i++) {
      this.circles[i] = this.drawPointAt([0, 0], i)
      let p = this.movePoint(i, this.initialCoords[i])
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

    const colors = ['#3f51b5', '#ffc107', '#ff5722', '#795548']

    const circle = this.createSvgEl('circle', {
      cx,
      cy,
      r: 3,
      fill: colors[index]
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

let initialCoords1 = [
  [0, 0],
  [4, 0],
  [10, 0],
  [7, 9]
]


let width = window.innerWidth * 0.7
let height = window.innerHeight * 0.8

let twoD1 = new TwoDViz({
  container: document.getElementById('two-d-viz-1'),
  width,
  height,
  minX: -0.2,
  maxX: 10.2,
  minY: -0.2,
  maxY: 9.2,
  initialCoords: initialCoords1,
  events: events1.events,
  showForcesAndArrows: true
})

twoD1.render()

let initialCoords2 = [
  [0, 0],
  [0, 0],
  [0, 0],
  [0, 0]
]

let twoD2 = new TwoDViz({
  container: document.getElementById('two-d-viz-2'),
  width,
  height,
  minX: -4.3,
  maxX: 5.2,
  minY: -4,
  maxY: 4.8,
  initialCoords: initialCoords2,
  events: events2.events,
  showForcesAndArrows: false
})

twoD2.render()
