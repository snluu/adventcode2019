import strutils

var OpsParamCount: array[0..99, int]

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
  echo "  Param: ", result

proc execCode(pos: int, codes: var seq[int64]): int =
  echo "Processing at position ", pos
  let x = codes[pos]
  let opsCode = x mod 100

  if codes[pos] == 99:
    return -1

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
    write(stdout, "Enter a number for position " & $p & ": ")
    let x = readline(stdin)
    codes[p] = parseBiggestInt(x)
  of 4: # output
    codes[0] = codes[codes[pos + 1]]
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

proc execProgram(codes: var seq[int64]): int64 =
  var pos = 0
  while pos != -1:
    pos = execCode(pos, codes)

  return codes[0]


proc main =
  initOpsParams()
  let rawInput = readFile("input.txt")
  let inputs = rawInput.strip().split(',')
  var codes: seq[int64]
  for i in inputs:
    codes.add(parseBiggestInt(i))

  echo "Program output: ", execProgram(codes)


when isMainModule:
  main()
