import math
import algorithm
import tables

const Width = 33
const Height = 33

type
  Asteroid = object
    x: int
    y: int
    canSee: int
  Target = object
    dist: int
    x, y: int

proc gcd(a, b: int): int =
  result = a
  var b = b
  while b > 0:
    let rem = result mod b
    result = b
    b = rem

proc canSee(a, b: Asteroid, hasAsteroid: openArray[bool]): bool =
  let gcd = gcd(abs(a.x - b.x), abs(a.y - b.y))
  if gcd == 1:
    # There's no path between the asteroids
    return true

  # echo "  GCD: ", gcd
  let deltaX = (b.x - a.x) div gcd
  let deltaY = (b.y - a.y) div gcd
  var x = a.x + deltaX
  var y = a.y + deltaY

  while x != b.x or y != b.y:
    # echo "  Checking ", x, ",", y
    let index = y * Width + x;

    if hasAsteroid[index]:
      return false
    x += deltaX
    y += deltaY

  return true

proc buildTargetList(
  asteroids: openArray[Asteroid],
  x, y: int,
): OrderedTable[float32, seq[Target]] =
  for i, a in asteroids:
    if a.x == x and a.y == y:
      continue

    let deltaX = abs(a.x - x)
    let deltaY = abs(a.y - y)

    var angle = 0'f32
    if deltaX == 0:
      angle = if a.y < y: 0 else: 180
    elif deltaY == 0:
      angle = if a.x < x: 270 else: 90
    else:
      if a.x > x:
        if a.y < y:
          # top right quadrant
          angle = radToDeg(arctan(float32(deltaX) / float32(deltaY)))
        elif a.y > y:
          # bottom right quadrant
          angle = 90 + radToDeg(arctan(float32(deltaY) / float32(deltaX)))
      elif a.x < x:
        if a.y > y:
          # bottom left quadrant
          angle = 180 + radToDeg(arctan(float32(deltaX) / float32(deltaY)))
        elif a.y < y:
          # top left quadrant
          angle = 270 + radToDeg(arctan(float32(deltaY) / float32(deltaX)))

    discard result.hasKeyOrPut(angle, @[])
    result[angle].add(Target(dist: deltaX + deltaY, x: a.x, y: a.y))


proc compareTargets(a, b: Target): int =
  return a.dist - b.dist


proc main =
  var input = readFile("input.txt")

  var asteroids: seq[Asteroid]
  var hasAsteroid: array[Width * Height, bool]

  var index = 0
  for c in input:
    if c == '.' or c == '#':
      if c == '#':
        asteroids.add(Asteroid(x: index mod Width, y: index div Width))
        hasAsteroid[index] = true
      index += 1 # we want to handle new lines and stuff so only +1 here

  echo "Found ", asteroids.len, " asteroid"

  var maxCanSee = 0
  var maxX = 0
  var maxY = 0
  for i in low(asteroids)..<high(asteroids):
    for j in i+1..high(asteroids):
      if canSee(asteroids[i], asteroids[j], hasAsteroid):
        # echo asteroids[i], " can see ", asteroids[j]
        asteroids[i].canSee += 1
        asteroids[j].canSee += 1
      # else:
        # echo asteroids[i], " can NOT see ", asteroids[j]
    if asteroids[i].canSee > maxCanSee:
      maxCanSee = asteroids[i].canSee
      maxX = asteroids[i].x
      maxY = asteroids[i].y
    # echo asteroids[i]

  echo "Max: ", maxCanSee

  var targets = buildTargetList(asteroids, maxX, maxY)

  var angles = newSeqOfCap[float32](targets.len)
  for angle in targets.keys:
    targets[angle] = sorted(targets[angle], compareTargets,
        SortOrder.Descending)
    angles.add(angle)

  angles = sorted(angles)

  var shotCount = 0
  while targets.len > 0:
    for angle in angles:
      if not targets.hasKey(angle):
        continue

      let target = targets[angle][^1]
      shotCount += 1
      echo "Shot #", shotCount, ": ", target.x, ",", target.y, ". Angle: ", angle

      targets[angle].del(targets[angle].len - 1)
      if targets[angle].len == 0:
        targets.del(angle)

      continue

when isMainModule:
  main()
