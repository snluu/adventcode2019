import strutils
import sets
import deques

var OpsParamCount: array[0..99, int]
const NumAmps = 5;
const PosHalted = -1'i64
const PosNoInput = -2'i64

type
  Program = object
    name: string
    codes: seq[int64]
    inputs: Deque[int64]
    outputs: Deque[int64]
    pos: int64
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

proc readParam(offset: int64, prog: Program, modes: var int64): int64 =
  let mode = modes mod 10
  modes = modes div 10
  if mode == 0:
    result = prog.codes[prog.codes[prog.pos + offset]]
  elif mode == 1:
    result = prog.codes[prog.pos + offset]
  else:
    assert false, "Unrecognized mode " & $mode
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
  echo "Processing at position ", prog.pos, ". Ops code: ", opsCode, ". Modes: ", paramModes

  
  assert(OpsParamCount[opsCode] > 0, "Unknown ops code: " & $opsCode)

  case opsCode
  of 1: # add
    let n1 = readParam(1, prog, paramModes)
    let n2 = readParam(2, prog, paramModes)
    prog.codes[prog.codes[prog.pos + 3]] = n1 + n2
  of 2: # mult
    let n1 = readParam(1, prog, paramModes)
    let n2 = readParam(2, prog, paramModes)
    prog.codes[prog.codes[prog.pos + 3]] = n1 * n2
  of 3: # input
    let p = prog.codes[prog.pos + 1]
    if prog.inputs.len == 0: return PosNoInput
    prog.codes[p] = prog.inputs.popFirst()
  of 4: # output
    prog.codes[0] = prog.codes[prog.codes[prog.pos + 1]]
    prog.outputs.addLast(prog.codes[0])
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
      return n2
  of 7: # less than
    let n1 = readParam(1, prog, paramModes)
    let n2 = readParam(2, prog, paramModes)
    prog.codes[prog.codes[prog.pos + 3]] = if n1 < n2: 1 else: 0
  of 8: # equals
    let n1 = readParam(1, prog, paramModes)
    let n2 = readParam(2, prog, paramModes)
    prog.codes[prog.codes[prog.pos + 3]] = if n1 == n2: 1 else: 0
  else:
    assert(false, "Unknown ops code: " & $opsCode)

  prog.pos += OpsParamCount[opsCode] + 1 # 1 for the ops code itself
  return prog.pos

proc execProgram(prog: var Program): int64 =
  while result >= 0 and not prog.halted:
    result = execCode(prog)

proc execAmplifiersLoop(
  codes: seq[int64],
  phases: array[NumAmps, int64],
  maxThruster: var int64,
) =
  var programs: array[NumAmps, Program]
  for i in low(programs)..high(programs):
    programs[i] = initProgram(codes)
    programs[i].name = $i
    programs[i].inputs.addLast(phases[i])
    
  programs[0].inputs.addLast(0)

  while not programs[^1].halted:
    for i,phase in phases:
      if programs[i].halted:
        continue

      discard execProgram(programs[i])
      let pipeOutputTo = if i == high(programs): 0 else: i + 1
      
      while programs[i].outputs.len > 0:
        programs[pipeOutputTo].inputs.addLast(programs[i].outputs.popFirst())
      
      if programs[i].halted and i == high(programs):
        let thruster = programs[i].codes[0]
        if thruster > maxThruster:
          maxThruster = thruster
          echo "Found new max thruster at ", maxThruster, " with phases ", phases
        return  

proc swap[T](arr: var openArray[T], x, y: int){.inline.} =
  if x == y:
    return

  let tmp = arr[x]
  arr[x] = arr[y]
  arr[y] = tmp

proc permutatePhases(
  phases: var array[NumAmps, int64],
  index: int,
  action: proc(arr: array[NumAmps, int64]),
) =
  if index == high(phases):
    action(phases)
    return
  
  for i in index..high(phases):
    swap(phases, i, index)
    permutatePhases(phases, index + 1, action)
    swap(phases, i, index)


proc main =
  initOpsParams()
  let rawInput = readFile("input.txt")
  let inputs = rawInput.strip().split(',')
  var codes: seq[int64]
  for i in inputs:
    codes.add(parseBiggestInt(i))

  var maxThruster: int64
  var phases = [0'i64, 1'i64, 2'i64, 3'i64, 4'i64]
  # var phases = [5'i64, 6'i64, 7'i64, 8'i64, 9'i64]
  permutatePhases(
    phases,
    0,
    proc(ps: array[NumAmps, int64]) =
      execAmplifiersLoop(codes, ps, maxThruster)      
  )

  echo "Max thruster: ", maxThruster

when isMainModule:
  main()
