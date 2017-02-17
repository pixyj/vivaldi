import Vector from './vector'
import events1 from './centralized-events-1'

const $ = window.$
const anime = window.anime


class TwoDViz {
  
  constructor({container,
               width, height,
               minX, maxX,
               minY, maxY,
               initialCoords, events}) {
    this.el = container;
    this.width = width
    this.height = height
    this.minX = minX
    this.maxX = maxX
    this.minY = minY
    this.maxY = maxY

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
  }

  reset() {
    this.nextEventIndex = 0
    this.empty()
    this.render()
    return this
  }

  async start() {
    while (this.nextEventIndex < this.length - 4) {
      await this.next()
    }
  }

  async next() {
    const event = this.events[this.nextEventIndex++]
    const endPoints = event.forces.map(({from, vector}) => {
      return [event.x_i, event.coords[from]]
    })
    await this.drawLines(endPoints, {cls: 'force', stroke: '#F44336'})
    await this.drawLines([[event.x_i, event.totalForce]], {cls: 'force', stroke: '#FFEB3B'})
    await this.drawLines([[event.x_i, event.x_i_next]], {cls: 'force-step', stroke: '#673AB7'})
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
    this.circles = this.initialCoords.map((coord, i) => {
      return this.drawPointAt(coord, i)
    })
    return this
  }

  empty() {
    while (this.el.hasChildNodes()) {
      this.el.removeChild(this.el.lastChild)
    }
  }

  movePoint(index, [cx, cy]) {
    return new Promise((resolve, reject) => {
      let circle = this.circles[index]
      $(circle).animate(
        {cx, cy},
        {
          step: function(v1) {$(this).attr('cx', v1)},
          complete: function() {
            resolve()
          }
        }
      )
    })
  }

  toSVGCoord(coord) {
    const [x, y] = coord

    const margin = 10

    const rangeX = (this.maxX - this.minX) + margin
    const svgX = margin + (x-this.minX)*this.width/rangeX

    const rangeY = (this.maxY - this.minY) + margin
    const svgY = margin + (this.maxY - y)*this.height/rangeY

    return [svgX, svgY]
  }

  drawPointAt([cx, cy], index) {
    const circle = this.createSvgEl('circle', {
      cx,
      cy,
      r: 3,
      fill: 'red'
    })
    this.svg.appendChild(circle)
    return circle
  }

  drawLines(endPoints, options) {
    let {cls, stroke} = options
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
            'marker-end': 'url(#Triangle)'
        })
        this.svg.appendChild(line)
        lines.push(line)

        currentProps[i * 2] = x1
        currentProps[i * 2 + 1] = y1
        targetProps[i * 2] = x2
        targetProps[i * 2 + 1] = y2
      })

      const lineCount = endPoints.length

      let animationProps = {
        duration: 30 * (this.length - this.nextEventIndex) / this.length,
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

let initialCoords = [
  [0, 0],
  [4, 0],
  [10, 0],
  [7, 7]
]

let twoD = new TwoDViz({
  container: document.getElementById('two-d-viz-1'),
  width: 1200,
  height: 600,
  minX: 0,
  maxX: 12,
  minY: 0,
  maxY: 8,
  initialCoords,
  events: events1.events
})

twoD.render()

window.t = twoD;

