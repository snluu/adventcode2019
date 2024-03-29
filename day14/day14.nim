import strutils
import tables
import strformat

type
  Chemical = tuple
    name: string
    quantity: int64
  Reaction = object
    result: Chemical
    inputs: seq[Chemical]

proc parseChem(s: string): Chemical =
  let parts = s.strip().split(' ')
  assert parts.len == 2
  result.name = parts[1]
  result.quantity = parseBiggestInt(parts[0])

proc parseChems(s: string): seq[Chemical] =
  let parts = s.split(',')
  assert parts.len > 0
  for p in parts:
    result.add(parseChem(p))


proc calculateOres(
  forName: string, quantity: int64,
  reactions: Table[string, Reaction],
  inventory: var Table[string, int64]): int64 =
  if quantity == 0 or forName == "ORE":
    # echo " --> ", quantity, " of ", forName
    return quantity

  assert reactions.hasKey(forName)

  var quantityFromInventory = min(inventory[forName], quantity)
  inventory[forName] -= quantityFromInventory
  let quantityNeeded = quantity - quantityFromInventory

  if quantityNeeded == 0:
    # echo fmt("{forName}: used {quantityFromInventory} from inventory. None made")
    return 0

  var multiplier = 0'i64
  if quantityNeeded <= reactions[forName].result.quantity:
    multiplier = 1
  else:
    multiplier = quantityNeeded div reactions[forName].result.quantity
    if quantityNeeded mod reactions[forName].result.quantity != 0:
      multiplier += 1

  let quantityMade = reactions[forName].result.quantity * multiplier
  assert quantityMade >= quantityNeeded
  let leftOver = quantityMade - quantityNeeded
  inventory[forName] += leftOver

  # echo fmt("{forName}: making {quantityMade}, needed {quantityNeeded}, leftover {leftOver}")

  for input in reactions[forName].inputs:
    let sub = calculateOres(
      input.name, input.quantity * multiplier, reactions, inventory)
    result += sub


  # echo result, " ORE needed for ", quantityNeeded, " ", forName


proc main =
  var reactions: Table[string, Reaction]
  var inventory: Table[string, int64]

  for line in lines("input.txt"):
    var parts = line.split("=>")
    assert parts.len == 2
    var result = parseChem(parts[1])

    assert not reactions.hasKey(result.name)
    reactions[result.name] = Reaction(result: result, inputs: parseChems(parts[0]))
    inventory[result.name] = 0

  let maxOres = 1000000000000'i64

  let oresForOneFuel = calculateOres("FUEL", 1, reactions, inventory)
  echo "Part 1: ", oresForOneFuel

  var searchHigh = (maxOres div oresForOneFuel) * 2
  var searchLow = 1'i64

  while searchLow < (searchHigh - 1):
    echo "Low: ", searchLow, ". High: ", searchHigh
    let search = (searchHigh + searchLow) div 2
    for k in inventory.keys:
      inventory[k] = 0

    let ores = calculateOres("FUEL", search, reactions, inventory)
    if ores > maxOres:
      searchHigh = search
    else:
      searchLow = search

    # echo "Low: ", searchLow, ". High: ", searchHigh

  echo "Part 2: ", searchLow

when isMainModule:
  main()
