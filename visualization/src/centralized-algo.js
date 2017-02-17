import Vector from './vector';


export default function simulate(coords, latencyMatrix, updateNodeIndices) {
  let updateEvents = []
  for (let i of updateNodeIndices) {
    const event = centralizedVivaldi(coords, latencyMatrix, 0.3, i)
    updateEvents.push(event)
    coords[i] = event.x_i_next
  }
  return updateEvents
}


const copyCoords = coords => coords.map(c => c)

function *otherNodeIndices(length, i) {
  for (let j = 0; j < length; j++) {
    if (j !== i) {
      yield j
    }
  }
}

function centralizedVivaldi(coords, latencyMatrix, t, i) {
  let forces = []
  const length = coords.length
  const x_i = coords[i]
  let totalForce = Vector.zero(2)
  for (let j of otherNodeIndices(length, i)) {
    const x_j = coords[j]
    const rtt = latencyMatrix[i][j]
    const e = rtt - Vector.distance(x_i, x_j)
    const force = Vector.scale(Vector.unitVectorAt(x_i, x_j), e)
    forces.push({
      from: j,
      vector: force
    })
    totalForce = Vector.add(force, totalForce)
  }
  const forceStep = Vector.scale(totalForce, t)
  const x_i_next = Vector.add(x_i, forceStep)
  return {i, x_i, x_i_next, forces, totalForce, coords: copyCoords(coords)}
}

