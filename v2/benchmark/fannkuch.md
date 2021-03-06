module benchmark.fannkuch

// n = 10, 79.13 sec
// n = 11, 975 sec
// laptop: n = 10, 44.54 sec

function fannkuch(n)
{
	local perm = array.new(n, 0)
	local perm1 = array.range(n)
	local count = array.new(n, 0)

	local i = 0
	local j = 0
	local k = 0
	local t = 0
	local flips = 0
	local r = n
	local maxFlipsCount = 0
	local check = 0

	while(true)
	{
		if(check < 30)
		{
			foreach(p; perm1)
				writef(p + 1)

			writefln()
			check++
		}

		while(r != 1)
		{
			count[r - 1] = r
			r--
		}

		if(!(perm1[0] == 0 || perm1[n - 1] == n - 1))
		{
			perm[] = perm1

			flips = 0
			i = perm[0]

			do
			{
				j = 1
				k = i - 1

				while(j < k)
				{
					t = perm[j]
					perm[j] = perm[k]
					perm[k] = t

					j++
					k--
				}

				flips++
				t = perm[i]
				perm[i] = i
				i = t
			} while(i)

			if(flips > maxFlipsCount)
				maxFlipsCount = flips
		}

		while(true)
		{
			if(r == n)
				return maxFlipsCount

			t = perm1[0]

			for(i = 0; i < r;)
			{
				j = i + 1
				perm1[i] = perm1[j]
				i = j
			}

			perm1[r] = t
			count[r]--

			if(count[r] > 0)
				break

			r++
		}
	}
}

function main(N)
{
	local n = 10

	if(isString(N))
		try n = toInt(N); catch(e) {}

	local timer = time.PerfCounter.clone()
	timer.start()

	writefln("Pfannkuchen({}) = {}", n, fannkuch(n))

	timer.stop()
	writefln("Took {} sec", timer.seconds())
}