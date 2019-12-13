type
  Vector3D = object
    x, y, z: int
  Moon = object
    at, velocity: Vector3D

proc runStep(moons: var openArray[Moon]) =
  for i in low(moons)..<high(moons):
    for j in i+1..high(moons):
      if moons[i].at.x < moons[j].at.x:
        moons[i].velocity.x += 1
        moons[j].velocity.x -= 1
      elif moons[i].at.x > moons[j].at.x:
        moons[i].velocity.x -= 1
        moons[j].velocity.x += 1

      if moons[i].at.y < moons[j].at.y:
        moons[i].velocity.y += 1
        moons[j].velocity.y -= 1
      elif moons[i].at.y > moons[j].at.y:
        moons[i].velocity.y -= 1
        moons[j].velocity.y += 1

      if moons[i].at.z < moons[j].at.z:
        moons[i].velocity.z += 1
        moons[j].velocity.z -= 1
      elif moons[i].at.z > moons[j].at.z:
        moons[i].velocity.z -= 1
        moons[j].velocity.z += 1

  for moon in moons.mitems:
    moon.at.x += moon.velocity.x
    moon.at.y += moon.velocity.y
    moon.at.z += moon.velocity.z

proc toString(vec: Vector3D): string =
  result = "x=" & $vec.x & ", y=" & $vec.y & ", z=" & $vec.z

proc potentialEnergy(moon: Moon): int =
  abs(moon.at.x) + abs(moon.at.y) + abs(moon.at.z)

proc kineticEnergy(moon: Moon): int =
  abs(moon.velocity.x) + abs(moon.velocity.y) + abs(moon.velocity.z)

proc echoMoons(moons: openArray[Moon]) =
  for moon in moons:
    echo "pos=<", moon.at.toString, ">; vel=<", moon.velocity.toString, ">"

proc main =
  # let input = [
  #   Moon(at: Vector3D(x: -1, y: 0, z: 2)),
  #   Moon(at: Vector3D(x: 2, y: -10, z: -7)),
  #   Moon(at: Vector3D(x: 4, y: -8, z: 8)),
  #   Moon(at: Vector3D(x: 3, y: 5, z: -1)),
  # ]
  let input = [
    Moon(at: Vector3D(x: -8, y: -10, z: 0)),
    Moon(at: Vector3D(x: 5, y: 5, z: 10)),
    Moon(at: Vector3D(x: 2, y: -7, z: 3)),
    Moon(at: Vector3D(x: 9, y: -8, z: -3)),
  ]

  # Puzzle input
  # let input = [
  #   Moon(at: Vector3D(x: -3, y: 10, z: -1)),
  #   Moon(at: Vector3D(x: -12, y: -10, z: -5)),
  #   Moon(at: Vector3D(x: -9, y: 0, z: 10)),
  #   Moon(at: Vector3D(x: 7, y: -5, z: -3)),
  # ]

  var moons = input

  echo "Initial:"
  echoMoons(moons)
  # for i in 1..1000:
  var steps = 0'i64
  while true:
    steps += 1
    runStep(moons)
    if moons == input:
      break
    # echo "After step ", i, ":"
    # echoMoons(moons)

  echo "Took ", steps, " steps"

  # var total = 0
  # for moon in moons:
  #   let pot = potentialEnergy(moon)
  #   let kin = kineticEnergy(moon)
  #   total += pot * kin
  #   echo "Potenial energy: ", pot, "; Kinetic energy: ", kin, "; Total: ", pot * kin
  # echo "Sum of moon energy: ", total


when isMainModule:
  main()
