import strutils
import tables

type
  Node = ref object
    name: string
    parent: Node
    orbits: int
    visited: bool

proc calculateOrbits(node: var Node) =
  if node.parent == nil:
    node.orbits = 1
    echo node.name, " = ", node.orbits
    return

  if node.parent.orbits == 0:
    calculateOrbits(node.parent)
  node.orbits = node.parent.orbits + 1
  echo node.name, " = ", node.orbits

proc findVisitedNode(node: var Node): Node =
  if node == nil:
    return nil

  if node.visited:
    return node

  node.visited = true
  return findVisitedNode(node.parent)

proc main =
  var f: File
  assert(open(f, "input.txt", fmRead), "Cannot open file")

  var orbits: Table[string, Node]

  for line in lines(f):
    let parts = line.split(')')
    let inner = parts[0]
    let outter = parts[1]

    var innerNode: Node
    if inner != "COM":
      innerNode = orbits.getOrDefault(inner, nil)
      if innerNode == nil:
        echo "Creating new node for ", inner
        var newNode: Node
        new(newNode)
        newNode.name = inner
        newNode.parent = nil
        innerNode = newNode
        orbits[inner] = innerNode

    let outterNode = orbits.getOrdefault(outter, nil)
    if outterNode == nil:
      echo "Creating new node for ", outter
      var newNode: Node
      new(newNode)
      newNode.name = outter
      newNode.parent = innerNode
      orbits[outter] = newNode
    else:
      outterNode.parent = innerNode

  echo "Found ", orbits.len, " nodes"

  var totalOrbits: int64
  for n in orbits.mvalues:
    if n.orbits == 0:
      calculateOrbits(n)
    totalOrbits += n.orbits

  echo "Total orbits: ", totalOrbits

  var santa = orbits["SAN"]
  assert santa != nil
  assert findVisitedNode(santa) == nil

  var you = orbits["YOU"]
  let n = findVisitedNode(you)
  assert n != nil

  echo "Found node ", n.name, " on the path to Santa"
  echo "Shortest path to Santa: ", you.parent.orbits - n.orbits +
      santa.parent.orbits - n.orbits

when isMainModule:
  main()
