import parseutils
import strutils

type
  Point = tuple
    x: int
    y: int

proc intersects(
  pa1: Point, pa2: Point, pb1: Point, pb2: Point, at: var Point,
): bool =
  # echo "Checking if (", pa1, ",", pa2, ") intersects with (", pb1, ",", pb2, ")"
  if pa1.x == pa2.x and pb1.x == pb2.x:
    # both lines are vertical
    return false

  if pa1.y == pa2.y and pb1.y == pb2.y:
    # both lines are horizontal
    return false

  if pa1.x == pa2.x:
    # A is vertical, B is horizontal
    if pa1.x < min(pb1.x, pb2.x) or pa1.x > max(pb1.x, pb2.x):
      return false
    if pb1.y < min(pa1.y, pa2.y) or pb1.y > max(pa1.y, pa2.y):
      return false
    at.x = pa1.x
    at.y = pb1.y
  else:
    # B is vertical, A is horizontal
    if pb1.x < min(pa1.x, pa2.x) or pb1.x > max(pa1.x, pa2.x):
      return false
    if pa1.y < min(pb1.y, pb2.y) or pa1.y > max(pb1.y, pb2.y):
      return false
    at.x = pb1.x
    at.y = pa1.y

  if at.x == 0 and at.y == 0:
    return false

  # echo "Intersects at: ", at
  return true

proc steps(p1: Point, p2: Point): int =
  if p1.x == p2.x:
    result = abs(p1.y - p2.y)
  else:
    result = abs(p1.x - p2.x)

proc convertToPoints(input: string): seq[Point] =
  result.add((x: 0, y: 0))
  for step in input.split(','):
    let lastPoint = result[^1]
    var val: int
    assert parseInt(step, val, 1) > 0
    case step[0]
    of 'U':
      result.add((x: lastPoint.x, y: lastPoint.y + val))
    of 'D':
      result.add((x: lastPoint.x, y: lastPoint.y - val))
    of 'L':
      result.add((x: lastPoint.x - val, y: lastPoint.y))
    of 'R':
      result.add((x: lastPoint.x + val, y: lastPoint.y))
    else:
      assert false


proc main =
  var f: File
  assert open(f, "input.txt", fmRead)
  defer: f.close()

  var wireInput1: string
  var wireInput2: string

  assert f.readLine(wireInput1)
  assert f.readLine(wireInput2)

  let wire1 = convertToPoints(wireInput1.strip())
  let wire2 = convertToPoints(wireInput2.strip())

  var minDist = high(int)
  var minSteps = high(int)

  # echo "Wire 1: ", wire1
  # echo "Wire 2: ", wire2
  var steps1 = 0
  for i1 in 1..high(wire1):
    var steps2 = 0
    for i2 in 1..high(wire2):
      var at: Point
      if intersects(wire1[i1-1], wire1[i1], wire2[i2-1], wire2[i2], at):
        let dist = abs(at.x) + abs(at.y)
        minDist = min(dist, minDist)

        let steps1AtIntersection = steps1 + steps(wire1[i1-1], at)
        let steps2AtIntersection = steps2 + steps(wire2[i2-1], at)
        minSteps = min(minSteps, steps1AtIntersection + steps2AtIntersection)

      steps2 += steps(wire2[i2-1], wire2[i2])

    steps1 += steps(wire1[i1-1], wire1[i1])

  echo "Minimum distance: ", minDist
  echo "Minimum steps: ", minSteps

when isMainModule:
  main()
