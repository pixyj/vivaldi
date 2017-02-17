import simulate from './../src/centralized-algo';


describe('centralized Vivaldi Simulation', () => {
  it('should update coordinates to minimize total force', () => {

    expect.extend()

    function zeros(count) {
      let a = new Array(count)
      for (let i = 0; i < count; i++) {
        a[i] = 0
      }
      return a
    }

    let coords = [
      [0, 0],
      [4, 0],
      [10, 0],
      [7, 7]
    ]
    let latencyMatrix = [
      [0.0, 5.0, 5.0, 3.0],
      [5.0, 0.0, 6.0, 7.615773105863909],
      [5.0, 6.0, 0.0, 7.615773105863909],
      [3.0, 7.615773105863909, 7.615773105863909, 0.0]
    ]

    let updateNodeIndices = zeros(25)
    let events = simulate(coords, latencyMatrix, updateNodeIndices)
    const lastEvent = events[events.length-1]
    const x_i_last = lastEvent.x_i_next

    expect.extend({
      toBeApproximatelyEqualVectors(a, b) {
        const pass = (function() {
          for (let i = 0, length = a.length; i < length; i++) {
            if (Math.abs(a[i] - b[i]) > 0.02) {
              return false
            }
          }
          return true
        })()

        return {
          pass: pass,
          message: () => `expected ${b} to be a approximately equal to ${a}`,
        }
      }
    });
    expect(x_i_last).toBeApproximatelyEqualVectors([7, 4])
  });
});
