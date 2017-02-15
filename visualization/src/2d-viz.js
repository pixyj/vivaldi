class TwoDViz {
  
  constructor({container, width, height, minX, maxX, minY, maxY, initialCoords, events}) {
    this.el = container;
    this.width = width
    this.height = height
    this.minX = minX
    this.maxX = maxX
    this.minY = minY
    this.maxY = maxY
    this.initialCoords = initialCoords
    this.events = events
    this.nextEventIndex = 0;
  }

  reset() {
    this.nextEventIndex = 0
    this.empty()
    this.render()
    return this
  }

  empty() {
    while (this.el.hasChildNodes()) {
      this.el.removeChild(this.el.lastChild)
    }
  }

  render() {
    this.initializeSvg()
    this.initialCoords.forEach(coord => {
      const point = this.toSVGCoord(coord)
      this.drawPointAt(point)
    })
    return this
  }

  movePoint(index, nextCoord) {

  }

  toSVGCoord(coord) {
    const margin = 10
    const [x, y] = coord
    const rangeX = (this.maxX - this.minX) + margin
    const svgX = margin + (x-this.minX)*this.width/rangeX

    const rangeY = (this.maxY - this.minY) + margin
    const svgY = margin + (this.maxY - y)*this.height/rangeY

    return [svgX, svgY]
  }

  drawPointAt([cx, cy]) {
    const circle = this.createSvgEl('circle', {
      cx,
      cy,
      r: 3,
      fill: 'red'
    })
    this.svg.appendChild(circle)
  }

  drawLineBetween(p1, p2) {

  }

  next() {

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

  // drawLineBetween(a, b) {
  //   var line = this.createSvgEl('line', {
  //       x1: a[0],
  //       y1: a[1],
  //       x2: b[0],
  //       y2: b[1],
  //       stroke: 'red',
  //       'stroke-width': 1,
  //       'marker-end': 'url(#Triangle)'
  //   });
  //   this.svg.appendChild(line);
  // }

  getTriangleMarkerDefinition() {
    let marker = document.createElementNS('http://www.w3.org/2000/svg', 'marker')
    const markerAttrs = {
        'id': 'Triangle',
        'viewBox': '0 0 10 10',
        'refX': '0',
        'refY': '5',
        'markerWidth': '10',
        'markerHeight': '10',
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

let events1 = [
  {
    index: 0,
    force: [10, 10],
    next: [1, 1]
  },
  {
    index: 0,
    force: [10, 20],
    next: [2, 3]
  }
]

let twoD = new TwoDViz({
  container: document.getElementById('two-d-viz-1'),
  width: 500,
  height: 500,
  minX: 0,
  maxX: 10,
  minY: 0,
  maxY: 10,
  initialCoords: [[3, 4], [5, 6], [8, 4], [0, 0]],
  events: events1
})

twoD.render()

window.twoD = twoD;

