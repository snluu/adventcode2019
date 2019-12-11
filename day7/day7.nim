import strutils
import sets
import deques

var OpsParamCount: array[0..99, int]
const NumAmps = 5;
const PosHalted = -1
const PosNoInput = -2

type
  ProgramInputs = Deque[int64]

proc initOpsParams =
  OpsParamCount[1] = 3
  OpsParamCount[2] = 3
  OpsParamCount[3] = 1
  OpsParamCount[4] = 1
  OpsParamCount[5] = 2
  OpsParamCount[6] = 2
  OpsParamCount[7] = 3
  OpsParamCount[8] = 3

proc readParam(pos: int, codes: var seq[int64], modes: var int64): int64 =
  let mode = modes mod 10
  modes = modes div 10
  if mode == 0:
    result = codes[codes[pos]]
  else:
    result = codes[pos]
  # echo "  Param: ", result

proc execCode(
  pos: int,
  codes: var seq[int64],
  pi: var ProgramInputs,
  outputAction: proc (val: int64),
): int =
  let x = codes[pos]
  let opsCode = x mod 100

  if opsCode == 99:
    return -1

  echo "Processing at position ", pos, ". Ops code: ", opsCode
  var paramModes = x div 100

  assert(OpsParamCount[opsCode] > 0, "Unknown ops code: " & $opsCode)

  case opsCode
  of 1: # add
    let n1 = readParam(pos + 1, codes, paramModes)
    let n2 = readParam(pos + 2, codes, paramModes)
    codes[codes[pos + 3]] = n1 + n2
  of 2: # mult
    let n1 = readParam(pos + 1, codes, paramModes)
    let n2 = readParam(pos + 2, codes, paramModes)
    codes[codes[pos + 3]] = n1 * n2
  of 3: # input
    let p = codes[pos + 1]
    if pi.len == 0:
      return PosNoInput
    codes[p] = pi.popFirst()
  of 4: # output
    codes[0] = codes[codes[pos + 1]]
    outputAction(codes[0])
  of 5: # jump if true
    let n1 = readParam(pos + 1, codes, paramModes)
    let n2 = readParam(pos + 2, codes, paramModes)
    if n1 != 0:
      return int(n2)
  of 6: # jump if false
    let n1 = readParam(pos + 1, codes, paramModes)
    let n2 = readParam(pos + 2, codes, paramModes)
    if n1 == 0:
      return int(n2)
  of 7: # less than
    let n1 = readParam(pos + 1, codes, paramModes)
    let n2 = readParam(pos + 2, codes, paramModes)
    codes[codes[pos + 3]] = if n1 < n2: 1 else: 0
  of 8: # equals
    let n1 = readParam(pos + 1, codes, paramModes)
    let n2 = readParam(pos + 2, codes, paramModes)
    codes[codes[pos + 3]] = if n1 == n2: 1 else: 0
  else:
    assert(false, "Unknown ops code: " & $opsCode)

  return pos + OpsParamCount[opsCode] + 1 # 1 for the ops code itself

proc execProgramAt(
  codes: var seq[int64],
  pi: var ProgramInputs,
  outputAction: proc (val: int64) = proc (val: int64) = discard,
  pos: var int,
): int =
  result = pos
  while result >= 0:
    result = execCode(pos, codes, pi, outputAction)
    if result >= 0:
      pos = result

proc execProgram(
  codes: var seq[int64],
  pi: var ProgramInputs,
  outputAction: proc (val: int64) = proc (val: int64) = discard,
): int =
  var pos = 0
  result = execProgramAt(codes, pi, outputAction, pos)
  assert result == -1

proc execAmplifiers(
  codes: seq[int64],
  phases: array[NumAmps, int64],
  maxThruster: var int64,
) =
  var output = 0'i64
  for i, phase in phases:
    var pi: ProgramInputs = initDeque[int64]()
    pi.addLast(phase)
    pi.addLast(output)

    var codesCopy = codes
    assert execProgram(codesCopy, pi) == -1
    output = codesCopy[0]
  
  if output > maxThruster:
    maxThruster = output
    echo "Found new max thruster at ", maxThruster, " with phases ", phases

proc execAmplifiersLoop(
  codes: seq[int64],
  phases: array[NumAmps, int64],
  maxThruster: var int64,
) =
  var inputs: array[NumAmps, ProgramInputs]
  var ampCodes: array[NumAmps, seq[int64]]
  var positions: array[NumAmps, int]
  var done: array[NumAmps, bool]
  for i in low(inputs)..high(inputs):
    inputs[i] = initDeque[int64]()
    inputs[i].addLast(phases[i])
    ampCodes[i] = codes # copy
  
  inputs[0].addLast(0)

  while true:
    for i,phase in phases:
      if done[i]:
        continue

      let returnCode = execProgramAt(
        ampCodes[i],
        inputs[i],
        proc(outputVal: int64) =
          if i == high(inputs):
            inputs[0].addLast(outputVal)
          else:
            inputs[i+1].addLast(outputVal),
        positions[i]
      )

      if returnCode == PosHalted:
        done[i] = true
        if i == high(done):
          let thruster = ampCodes[i][0]
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
  # var phases = [0'i64, 1'i64, 2'i64, 3'i64, 4'i64]
  var phases = [5'i64, 6'i64, 7'i64, 8'i64, 9'i64]
  permutatePhases(
    phases,
    0,
    proc(ps: array[NumAmps, int64]) =
      # execAmplifiers(codes, ps, maxThruster)
      execAmplifiersLoop(codes, ps, maxThruster)      
  )

  echo "Max thruster: ", maxThruster

when isMainModule:
  main()
