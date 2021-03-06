module tests.array

import tests.common : xfail

// minid.array
local a = [1 2 3]
a = a[1 ..]
a[] = [4 5]
#a = 10
a[3 .. 5] = a[4 .. 6]
a = [1, 2, (\->3)()]
local x = 3 in a
x = 5 in a
a = a ~ [1]
a = a ~ 1
a = [i for i in 1 .. 3]
a = array.new(1000)
a = array.new(300)

// minid.arraylib
a = array.new(5)
array.new(10, 0)
xfail$\{ array.new(-3) }

a = array.range(10)
array.range(3, 8)
array.range(2, 10, 3)
xfail$\{ array.range(1, 10, -2) }
array.range(10, 2)

a.sort()
a.sort("reverse")
a.sort(\x, y -> x <=> y)
xfail$\{ a.sort(\x, y -> null) }
a.reverse()
a.dup()

foreach(i, v; a){}
foreach(i, v; a, "reverse"){}
a.expand()
a.toString();
["hi", 'c'].toString()
a.apply(\x -> x)
a.map(\x -> x)
a.reduce(\x, y -> x);
[].reduce(\x, y -> x)
a.each(\i, v -> false)
array.range(100).filter(\i, v -> true)
xfail$\{ a.filter(\i -> null) }

a.find(5)
a.find(8980)
a.findIf(\v -> !toBool(v & 1))
a.findIf(\v -> v == 5239)
xfail$\{ a.findIf(\v -> null) }
a = array.range(50)
a.bsearch(3)
a.bsearch(-54)
a.bsearch(24)
a.bsearch(50)
a.pop()
a.pop(0)
a.pop(-1)
xfail$\{ a.pop(-500000) }
xfail$\{ [].pop() }

a.set(3, 2, 1)
a.min()
a.set(1, 2, 3)
a.max()
a.set()
xfail$\{ a.min() }
a.set(2, 7, 4, 1, 2, 6)
a.extreme(\a, b -> a < b)
xfail$\{ a.extreme(\a -> null) }
a.all()
a.all(\a -> a)
a.any()
a.any(\a -> a)
a.fill(5)
a.append()
a.append(1, 2, 3);
[[1 2], [3 4]].flatten()
xfail$\{ local x = [0]; x[0] = x; x.flatten() }

a = [1 2 3 4 5 6 7 8 9 10]
a.makeHeap()
a.pushHeap(11)
a.popHeap()
xfail$\{ [].popHeap() }
a.sortHeap()

a = [1 2 2 3 4 5 5 5 5]
a.count(2)
a.count(2, \x, y -> x == y)
xfail$\{ a.count(2, \x, y -> null) }
a.countIf(\x -> toBool(x & 1))
xfail$\{ a.countIf(\x -> null) }