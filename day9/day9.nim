import strutils
import deques

var OpsParamCount: array[0..99, int]
const PosHalted = -1'i64
const PosNoInput = -2'i64

type
  Program = object
    name: string
    codes: seq[int64]
    inputs: Deque[int64]
    outputs: Deque[int64]
    pos: int64
    relativeBase: int64
    halted: bool

proc initProgram(codes: seq[int64]): Program =
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
    let output = prog.codes[readAddr(1, prog, paramModes)]
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

proc main =
  initOpsParams()
  let rawInput = readFile("input.txt")
  let inputs = rawInput.strip().split(',')
  var codes = newSeq[int64](10240)
  for i, n in inputs:
    codes[i] = parseBiggestInt(n)

  var prog = initProgram(codes)
  prog.inputs.addLast(2)

  assert execProgram(prog) == -1
  echo prog.outputs

when isMainModule:
  main()
