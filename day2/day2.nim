from strutils import split
from parseutils import parseBiggestInt

proc execCode(pos: int, codes: var seq[int64]): int =
    if codes[pos] == 99:
        return -1

    let opsCode = codes[pos]
    assert opsCode == 1 or opsCode == 2

    if opsCode == 1:
        codes[codes[pos + 3]] = codes[codes[pos + 1]] + codes[codes[pos + 2]]
    elif opsCode == 2:
        codes[codes[pos + 3]] = codes[codes[pos + 1]] * codes[codes[pos + 2]]

    return pos + 4

proc execProgram(codes: var seq[int64], noun: int64, verb: int64): int64 =
    codes[1] = noun
    codes[2] = verb
    var pos = 0
    while pos != -1:
        pos = execCode(pos, codes)

    return codes[0]


proc main =
    let input = readFile("input.txt")
    let inputs = input.split(',')
    var nums = newSeq[int64](0)
    for i in inputs:
        var x: int64
        assert parseBiggestInt(i, x) > 0
        nums.add(x)

    block:
        var codes = nums
        echo "Part 1: ", execProgram(codes, 12, 2)

    for noun in 0..99:
        for verb in 0..99:
            var codes = nums
            if execProgram(codes, noun, verb) == 19690720:
                echo "Noun: ", noun, ". Verb: ", verb
                return


when isMainModule:
    main()
