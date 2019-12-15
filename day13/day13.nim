import strutils
import deques
import tables
import os
import terminal

var OpsParamCount: array[0..99, int]
const PosHalted = -1'i64
const PosNoInput = -2'i64
const ProgramSize = 202400

type
  Program = object
    name: string
    codes: array[ProgramSize, int64]
    inputs: Deque[int64]
    outputs: Deque[int64]
    pos: int64
    relativeBase: int64
    halted: bool

  Tile = object
    # count: int
    value: int

proc initProgram(codes: array[ProgramSize, int64]): Program =
  result.codes = codes
  result.inputs = initDeque[int64]()
  result.outputs = initDeque[int64]()

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
    result = prog.codes[prog.pos + offset]
  elif mode == 2:
    result = prog.relativeBase + prog.codes[prog.pos + offset]
  else:
    assert false, "readAddr -- unrecognized mode " & $mode
  # echo "  Address: ", result

proc readParam(offset: int64, prog: Program, modes: var int64): int64 =
  let mode = modes mod 10
  modes = modes div 10
  if mode == 0:
    result = prog.codes[prog.codes[prog.pos + offset]]
  elif mode == 1:
    result = prog.codes[prog.pos + offset]
  elif mode == 2:
    result = prog.codes[prog.relativeBase + prog.codes[prog.pos + offset]]
  else:
    assert false, "readParam -- unrecognized mode " & $mode
  # echo "  Param: ", result

proc execCode(prog: var Program): int64 =
  let x = prog.codes[prog.pos]
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

proc getTile(
  x, y, : int,
  tiles: Table[int, Table[int, Tile]],
): int =
  if tiles.hasKey(x) and tiles[x].hasKey(y):
    result = tiles[x][y].value

proc setTile(
  x, y, value: int,
  tiles: var Table[int, Table[int, Tile]],
) =
  # echo "Painting ", Colors[color], " at ", x, ",", y
  discard tiles.hasKeyOrPut(x, initTable[int, Tile]())
  discard tiles[x].hasKeyOrPut(y, Tile())

  tiles[x][y].value = value

proc main =
  initOpsParams()
  let rawInput = readFile("input.txt")
  let inputs = rawInput.strip().split(',')
  var codes: array[ProgramSize, int64]
  for i, n in inputs:
    codes[i] = parseBiggestInt(n)

  # Part 1
  var prog = initProgram(codes)
  prog.codes[0] = 2 # Part 2
  var tiles: Table[int, Table[int, Tile]]
  var tileTypeCount: array[0..4, int]

  var score, maxX, maxY, paddleX, ballX = 0

  eraseScreen(stdout)
  hideCursor(stdout)
  flushFile(stdout)
  while tileTypeCount[2] != 0 or score == 0:
    let output = execProgram(prog)
    # assert prog.outputs.len mod 3 == 0
    while prog.outputs.len > 0:
      let x = int(prog.outputs.popFirst())
      let y = int(prog.outputs.popFirst())
      maxX = max(x, maxX)
      maxY = max(y, maxY)
      let value = int(prog.outputs.popFirst())

      if x == -1 and y == 0:
        # update score
        if value != 0:
          score = value
      else:
        tileTypeCount[getTile(x, y, tiles)] -= 1
        setTile(x, y, value, tiles)
        tileTypeCount[value] += 1

      if value == 3 or value == 4:
        if value == 3: # paddle
          paddleX = x
        elif value == 4: # ball
          ballX = x

      setCursorPos(x, y)
      let c = case value:
      of 1: '#' # wall
      of 2: 'X' # block
      of 3: '_' # paddle
      of 4: '0' # ball
      else: ' '
      write(stdout, c)

    setCursorPos(0, maxY + 1)
    write(stdout, "Score: " & $score)
    flushFile(stdout)

    sleep(20)

    if output == PosNoInput:
      if ballX != paddleX:
        prog.inputs.addLast((ballX - paddleX) div abs(ballX - paddleX))
      else:
        prog.inputs.addLast(0)

    if prog.halted:
      prog.halted = false
      prog.pos = 0

  showCursor(stdout)
  # displayTiles(maxX, maxY, tiles)
  # echo "Score: ", score
  # sleep(5)

when isMainModule:
  main()
