import strutils

type
  LayerStat = array['0'..'9', int]
  ImageStat = seq[LayerStat]

proc main =
  let rawInput = readFile("input.txt")

  var imgStat: ImageStat

  const Width = 25
  const Height = 6
  const Size = Width * Height

  var pixels: array[Size, char];
  var pixelIndex = 0

  for i, d in rawInput:
    if not isDigit(d):
      break

    if i mod Size == 0:
      var layer: LayerStat
      imgStat.add(layer)
      pixelIndex = 0

    if pixels[pixelIndex] == '\0' or pixels[pixelIndex] == '2':
      pixels[pixelIndex] = d

    imgStat[^1][d] += 1
    pixelIndex += 1

  var minZeroes = high(int)
  var fewestZerosLayerIndex: int
  for i, layer in imgStat:
    if layer['0'] < minZeroes:
      fewestZerosLayerIndex = i
      minZeroes = layer['0']

  let layer = imgStat[fewestZerosLayerIndex]
  echo "Layer ", fewestZerosLayerIndex, " has the fewest zeroes with: ", layer
  echo layer['1'] * layer['2']

  for row in 0..<Height:
    for col in 0..<Width:
      let p = pixels[row * Width + col]
      write(stdout, if p == '1': '#' else: ' ')
    echo ""

when isMainModule:
  main()

