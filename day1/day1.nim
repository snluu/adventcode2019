from parseutils import parseBiggestInt

proc main =
    let f = open("input.txt", fmRead)
    defer: f.close()

    var
        line: string
        totalFuel = 0'i64
    while f.readLine(line):
        var mass: int64
        if parseBiggestInt(line, mass) > 0:
            totalFuel += (mass div 3) - 2

    echo "Total fuel: ", totalFuel


when isMainModule:
    main()
