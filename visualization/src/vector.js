export default {
  add(p1, p2) {
    return zip(p1, p2).map(value => value[0] + value[1])
  },

  diff(p1, p2) {
    return zip(p1, p2).map(value => value[0] - value[1])
  },

  distance(p1, p2) {
    return this.magnitude(this.diff(p1, p2));
  },

  magnitude(p1) {
    return Math.sqrt(p1.map(value => value * value).reduce((a, b) => a + b))
  },

  rand(dimension) {
    let a = new Array(dimension)
    for (let i = 0; i < dimension; i++) {
      a[i] = Math.random() - 0.5
    }
    return a
  },

  scale(p1, factor) {
    return p1.map(value => value * factor)
  },

  unitVectorAt(p1, p2) {
    if (this.isZero(p1) && this.isZero(p2)) {
      const r = this.rand(p1.length)
      return this.scale(r, 1 / this.magnitude(r))
    } else if (areEqual(p1, p2)) {
      return this.zero(p1.length)
    } else {
      const d = this.diff(p1, p2)
      const mag = this.magnitude(d)
      return this.scale(d, 1 / mag)
    }
  },

  zero(dimension) {
    let a = new Array(dimension);
    for (let i = 0; i < dimension; i++) {
      a[i] = 0
    }
    return a
  },

  isZero(p1) {
    for (let value of p1) {
      if (value !== 0) {
        return false;
      }
    }
    return true;
  }
}

function areEqual(p1, p2) {
  for (let [a, b] of zip(p1, p2)) {
    if (a !== b) {
      return false
    }
  }
  return true
}

function zip(p1, p2) {
  return p1.map((value, index) => [value, p2[index]])
}
