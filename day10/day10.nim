const Width = 33
const Height = 33

type
  Asteroid = object
    x: int
    y: int
    canSee: int

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
  for i in low(asteroids)..<high(asteroids):
    for j in i+1..high(asteroids):
      if canSee(asteroids[i], asteroids[j], hasAsteroid):
        # echo asteroids[i], " can see ", asteroids[j]
        asteroids[i].canSee += 1
        asteroids[j].canSee += 1
      # else:
        # echo asteroids[i], " can NOT see ", asteroids[j]
    maxCanSee = max(maxCanSee, asteroids[i].canSee)
    # echo asteroids[i]

  echo "Max: ", maxCanSee


when isMainModule:
  main()
