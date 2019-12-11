proc tryDigit(d: char, doubles: int, num: var string, count: var int,
    attempts: var int) =
  var doubles = doubles
  if num.len > 0 and d == num[^1]:
    if num.len > 1:
      if num[^2] != d:
        # found a new pair
        doubles += 1
      elif num.len == 2 or (num.len > 2 and num[^3] != d):
        # we found 3 numbers in a row.
        # if it's the first time we see these 3 in a row we should decrease "doubles"
        doubles -= 1
    else:
      doubles += 1

  num.add(d)
  if num.len() < 6:
    for dd in d..'9':
      tryDigit(dd, doubles, num, count, attempts)
  else:
    attempts += 1
    if doubles > 0:
      if num >= "183564" and num <= "657474":
        echo "Found potential password: ", num
        count += 1

  num.setLen(num.len - 1)

proc main =
  var
    num: string
    count, attempts: int

  for d in '1'..'9':
    tryDigit(d, 0, num, count, attempts)

  echo "Number of passwords: ", count
  echo "Number of attempts: ", attempts

when isMainModule:
  main()
