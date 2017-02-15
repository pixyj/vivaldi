import Vector from './../src/vector';

// all binary vector operations are assumed to be called with matching dimensions.

describe('add', () => {
  it('should add two vectors ', () => {
    const pointsAndResults = [
       [[1], [2], [3]],
       [[0, 0], [0, 0], [0, 0]],
       [[0, 1], [0, 0], [0, 1]],
       [[2, 1], [1, 2], [3, 3]],
       [[0, 3], [4, 0], [4, 3]],
    ];


    pointsAndResults.map((v) => {
      expect(Vector.add(v[0], v[1])).toEqual(v[2])
    })
  });
});

describe('diff', () => {
  it('should add diff vectors', () => {
    const pointsAndResults = [
      [[1], [2], [-1]],
      [[0, 0], [0, 0], [0, 0]],
      [[0, 1], [0, 0], [0, 1]],
      [[2, 1], [1, 2], [1, -1]],
      [[0, 3], [4, 0], [-4, 3]],
    ];

    pointsAndResults.map((v) => {
      expect(Vector.diff(v[0], v[1])).toEqual(v[2])
    })
  });
});

describe('distance', () => {
  it('should calculate distance between two vectors', () => {
    const pointsAndResults = [
      [[1], [1], 0.0],
      [[0, 0], [0, 0], 0.0],
      [[0, 1], [0, 0], 1.0],
      [[0, 0], [2, 0], 2.0],
      [[2, 1], [1, 2], Math.sqrt(2)],
      [[0, 3], [4, 0], 5.0],
    ];

    pointsAndResults.map((v) => {
      expect(Vector.distance(v[0], v[1])).toBe(v[2])
    })
  });
});

describe('magnitude', () => {
  it('should calculate distance of given vector from origin', () => {
    const pointAndResult = [
      [[1], 1.0],
      [[0, 0], 0.0],
      [[0, 1], 1.0],
      [[2, 0], 2.0],
      [[1, 1], Math.sqrt(2)],
      [[3, 4], 5.0],
    ];

    pointAndResult.map((v) => {
      expect(Vector.magnitude(v[0])).toBe(v[1])
    })
  });
});

describe('scale', () => {
  it('should scale vector by given factor', () => {
    const pointFactorAndResult = [
      [[1], 0, [0]],
      [[2], 1, [2]],
      [[0, 0], 1, [0, 0]],
      [[0, 1], 2, [0, 2]],
      [[1, 2], -2, [-2, -4]],
    ];

    pointFactorAndResult.map((v) => {
      expect(Vector.scale(v[0], v[1])).toEqual(v[2])
    })
  });
});


describe('unitVectorAt', () => {
  // ```
  //   Given two vectors p1 and p2, 
  //   if p1 and p2 are both equal to zero,
  //     it should return a random unit vector,
  //   else
  //     it should return unitVectorAt p1 - p2
  // ```
  it('should return a unit vector', () => {

    expect.extend({
      toBeARandomUnitVector(received) {
        const pass = (Vector.magnitude(received) - 1.0) < 0.0001
        return {
          pass: pass,
          message: () => `expected ${received} to be a random unit vector`,
        }
      },

      toBeApproximatelyEqualVectors(a, b) {
        const pass = (function() {
          for (let i = 0, length = a.length; i < length; i++) {
            if (Math.abs(a[i] - b[i]) > 0.0001) {
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

    expect(Vector.unitVectorAt([0, 0], [0, 0])).toBeARandomUnitVector()

    const pointsAndResults = [
      [[2, 2], [1, 1], [Math.cos(Math.PI/4), Math.sin(Math.PI/4)]],
      [[2, 1], [2, 0], [0, 1]],
    ];

    pointsAndResults.map((v) => {
      expect(Vector.unitVectorAt(v[0], v[1])).toBeApproximatelyEqualVectors(v[2])
    })

  });
});
