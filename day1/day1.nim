from parseutils import parseBiggestInt

proc calculateFuelForFuel(fuel: int64): int64 =
    var fuelRequired = (fuel div 3) - 2
    while fuelRequired > 0:
        result += fuelRequired
        fuelRequired = (fuelRequired div 3) - 2

proc main =
    let f = open("input.txt", fmRead)
    defer: f.close()

    var
        line: string
        fuelForParts = 0'i64
        fuelForFuel = 0'i64
    while f.readLine(line):
        var mass: int64
        if parseBiggestInt(line, mass) > 0:
            let fuel = (mass div 3) - 2
            fuelForParts += fuel
            fuelForFuel += calculateFuelForFuel(fuel)

    echo "Fuel for parts: ", fuelForParts
    echo "Fuel for fuel: ", fuelForFuel
    echo "Total: ", fuelForParts + fuelForFuel


when isMainModule:
    main()
