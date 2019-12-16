import strutils
import deques
import tables

var OpsParamCount: array[0..99, int]
const PosHalted = -1'i64
const PosNoInput = -2'i64

# north south east, east
const Directions = [1, 2, 3, 4]
const Deltas = [(0, -1), (0, 1), (1, 0), (-1, 0)]

type
  Program = object
    name: string
    codes: Table[int64, int64]
    inputs: Deque[int64]
    outputs: Deque[int64]
    pos: int64
    relativeBase: int64
    halted: bool
  VisitMap = Table[int64, Table[int64, int]]
  Node = object
    prog: Program
    x, y: int64

proc copyTable[K, V](t: Table[K, V]): Table[K, V] =
  for k, v in t:
    result[k] = v

proc initProgram(codes: Table[int64, int64]): Program =
  result.codes = copyTable(codes)
  result.inputs = initDeque[int64]()
  result.outputs = initDeque[int64]()

proc clonePrgram(p: Program): Program =
  result.name = p.name
  result = initProgram(p.codes)
  result.pos = p.pos
  result.relativeBase = p.relativeBase
  result.halted = p.halted

proc initOpsParams =
  OpsParamCount[1] = 3
  OpsParamCount[2] = 3
  OpsParamCount[3] = 1
  OpsParamCount[4] = 1
  OpsParamCount[5] = 2
  OpsParamCount[6] = 2
  OpsParamCount[7] = 3
  OpsParamCount[8] = 3
  OpsParamCount[9] = 1

proc readAddr(offset: int64, prog: Program, modes: var int64): int64 =
  let mode = modes mod 10
  modes = modes div 10
  if mode == 0:
    result = prog.codes.getOrDefault(prog.pos + offset, 0)
  elif mode == 2:
    result = prog.relativeBase + prog.codes.getOrDefault(prog.pos + offset, 0)
  else:
    assert false, "readAddr -- unrecognized mode " & $mode
  # echo "  Address: ", result

proc readParam(offset: int64, prog: Program, modes: var int64): int64 =
  let mode = modes mod 10
  modes = modes div 10
  if mode == 0:
    result = prog.codes.getOrDefault(prog.codes.getOrDefault(prog.pos + offset, 0), 0)
  elif mode == 1:
    result = prog.codes.getOrDefault(prog.pos + offset, 0)
  elif mode == 2:
    result = prog.codes.getOrDefault(prog.relativeBase +
        prog.codes.getOrDefault(prog.pos + offset, 0), 0)
  else:
    assert false, "readParam -- unrecognized mode " & $mode
  # echo "  Param: ", result

proc execCode(prog: var Program): int64 =
  let x = prog.codes.getOrDefault(prog.pos, 0)
  let opsCode = x mod 100

  if opsCode == 99:
    prog.halted = true
    return PosHalted

  var paramModes = x div 100

  if prog.name.len > 0:
    write(stdout, "Program " & prog.name & ": ")
  # echo "Processing at position ", prog.pos, ". Ops code: ", opsCode,
  #     ". Modes: ", paramModes


  assert(OpsParamCount[opsCode] > 0, "Unknown ops code: " & $opsCode)

  case opsCode
  of 1: # add
    let n1 = readParam(1, prog, paramModes)
    let n2 = readParam(2, prog, paramModes)
    let address = readAddr(3, prog, paramModes)
    prog.codes[address] = n1 + n2
    # echo "  Address @", address, " set to ", n1, " + ", n2, " = ", (n1 + n2)
  of 2: # mult
    let n1 = readParam(1, prog, paramModes)
    let n2 = readParam(2, prog, paramModes)
    prog.codes[readAddr(3, prog, paramModes)] = n1 * n2
  of 3: # input
    let address = readAddr(1, prog, paramModes)
    if prog.inputs.len == 0: return PosNoInput
    prog.codes[address] = prog.inputs.popFirst()
  of 4: # output
    let output = readParam(1, prog, paramModes)
    # echo "  Output: ", output
    prog.outputs.addLast(output)
  of 5: # jump if true
    let n1 = readParam(1, prog, paramModes)
    let n2 = readParam(2, prog, paramModes)
    if n1 != 0:
      prog.pos = n2
      return n2
  of 6: # jump if false
    let n1 = readParam(1, prog, paramModes)
    let n2 = readParam(2, prog, paramModes)
    if n1 == 0:
      prog.pos = n2
      # echo "  Jumping to ", n2
      return n2
  of 7: # less than
    let n1 = readParam(1, prog, paramModes)
    let n2 = readParam(2, prog, paramModes)
    prog.codes[readAddr(3, prog, paramModes)] = if n1 < n2: 1 else: 0
  of 8: # equals
    let n1 = readParam(1, prog, paramModes)
    let n2 = readParam(2, prog, paramModes)
    let address = readAddr(3, prog, paramModes)
    prog.codes[address] = if n1 == n2: 1 else: 0
    # echo "  Comparing ", n1, " and ", n2, ". Address ", address, " set to ",
    #     prog.codes[address]
  of 9: #
    prog.relativeBase += readParam(1, prog, paramModes)
    # echo "  Relative base set to ", prog.relativeBase
  else:
    assert(false, "Unknown ops code: " & $opsCode)

  prog.pos += OpsParamCount[opsCode] + 1 # 1 for the ops code itself
  return prog.pos

proc execProgram(prog: var Program): int64 =
  while result >= 0 and not prog.halted:
    result = execCode(prog)

proc visited(x, y: int64, m: VisitMap): bool =
  result = m.hasKey(x) and m[x].hasKey(y)

proc visit(x, y: int64, m: var VisitMap, value: int) =
  discard m.hasKeyOrPut(x, initTable[int64, int]())
  m[x][y] = value

proc mapValue(x, y: int64, m: VisitMap): int =
  if visited(x, y, m):
    result = m[x][y]

proc bfs(nodes: var openArray[Node], steps: int, m: var VisitMap): int =
  var nextSteps: seq[Node]
  for n in nodes.mitems:
    let retCode = execProgram(n.prog)
    assert retCode != PosHalted
    assert not n.prog.halted
    assert n.prog.outputs.len > 0
    let output = n.prog.outputs.popFirst()
    if output == 0: # hit a wall
      continue

    visit(n.x, n.y, m, int(output)) # fill the map
    if output == 2: # found the vent
      result = steps

    assert output == 1 or output == 2
    for dir in Directions:
      let x = n.x + Deltas[dir - 1][0]
      let y = n.y + Deltas[dir - 1][1]
      if visited(x, y, m):
        continue

      visit(x, y, m, 0)
      nextSteps.add(Node(prog: clonePrgram(n.prog), x: x, y: y))
      nextSteps[^1].prog.inputs.addLast(dir)

  if nextSteps.len > 0:
    result = max(result, bfs(nextSteps, steps + 1, m))

proc bfs2(
  coords: openArray[tuple[x: int64, y: int64]],
  m: var VisitMap,
  spaces: var int,
  minutes: int
): int =
  result = minutes + 1
  var next: seq[tuple[x: int64, y: int64]]
  for loc in coords:
    # echo "At ", loc.x, ",", loc.y
    for d in Deltas:
      let x = loc.x + d[0]
      let y = loc.y + d[1]
      if mapValue(x, y, m) == 1:
        spaces -= 1
        visit(x, y, m, 3)
        next.add((x: x, y: y))

  if spaces == 0:
    return

  return bfs2(next, m, spaces, minutes + 1)

proc main =
  initOpsParams()
  let rawInput = readFile("input.txt")
  let inputs = rawInput.strip().split(',')
  var codes: Table[int64, int64]
  for i, n in inputs:
    codes[i] = parseBiggestInt(n)

  var m: VisitMap
  visit(0, 0, m, 0)

  var nodes: array[1..4, Node]
  for dir in Directions:
    let x = Deltas[dir - 1][0]
    let y = Deltas[dir - 1][1]
    visit(x, y, m, 0)
    nodes[dir] = Node(prog: initProgram(codes), x: x, y: y)
    nodes[dir].prog.inputs.addLast(dir)

  echo "Part 1: ", bfs(nodes, 1, m)

  var startX, startY: int64
  var spaces: int
  for x, col in m:
    for y, val in col:
      if val == 2:
        startX = x
        startY = y
      elif val == 1:
        spaces += 1

  echo "Part 2: ", bfs2([(x: startX, y: startY)], m, spaces, 0)


when isMainModule:
  main()
