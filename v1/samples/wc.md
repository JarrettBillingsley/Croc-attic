module wc;

local w_total = 0;
local l_total = 0;
local c_total = 0;
local dictionary = { };

local args = [vararg];

if(#args == 0)
	return;

writefln("   lines   words   bytes  file");

foreach(arg; args)
{
	local w_cnt = 0;
	local l_cnt = 0;
	local inword = false;

	local c_cnt = io.size(arg);

	local f = io.File(arg);
	local buf = "";

	foreach(line; f)
	{
		foreach(c; line)
		{
			if(c == '\n')
				++l_cnt;
	
			if(c.isDigit())
			{
				if(inword)
					buf ~= c;
			}
			else if(c.isAlpha())
			{
				if(!inword)
				{
					buf = toString(c);
					inword = true;
					++w_cnt;
				}
				else
					buf ~= c;
			}
			else if(inword)
			{
				local val = dictionary[buf];
				
				if(val is null)
				{
					dictionary[buf] = 1;
					buf = "";
				}
				else
					dictionary[buf] += 1;
	
				inword = false;
			}
		}
	}
	
	f.close();

	if(inword)
		dictionary[buf] += 1;

	writefln("{,8}{,8}{,8}  {}\n", l_cnt, w_cnt, c_cnt, arg);
	l_total += l_cnt;
	w_total += w_cnt;
	c_total += c_cnt;
}

if(#args > 1)
	writefln("--------------------------------------\n{,8}{,8}{,8}  total", l_total, w_total, c_total);

writefln("--------------------------------------");

foreach(word; dictionary.keys().sort())
	writefln("{,3} {}", dictionary[word], word);