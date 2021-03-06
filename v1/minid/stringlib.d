/******************************************************************************
License:
Copyright (c) 2007 Jarrett Billingsley

This software is provided 'as-is', without any express or implied warranty.
In no event will the authors be held liable for any damages arising from the
use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it freely,
subject to the following restrictions:

    1. The origin of this software must not be misrepresented; you must not
	claim that you wrote the original software. If you use this software in a
	product, an acknowledgment in the product documentation would be
	appreciated but is not required.

    2. Altered source versions must be plainly marked as such, and must not
	be misrepresented as being the original software.

    3. This notice may not be removed or altered from any source distribution.
******************************************************************************/

module minid.stringlib;

import minid.types;
import minid.utils;

import Float = tango.text.convert.Float;
import Integer = tango.text.convert.Integer;
import tango.core.Array;
import Text = tango.text.Util;
import Uni = tango.text.Unicode;

class StringLib
{
	private static StringLib lib;
	
	static this()
	{
		lib = new StringLib();
	}
	
	private this()
	{
		
	}

	public static void init(MDContext context)
	{
		MDNamespace namespace = new MDNamespace("string"d, context.globals.ns);

		Iterator* iter = new Iterator;
		iter.iter = new MDClosure(namespace, &iter.iterator, "string.iterator");
		iter.iterReverse = new MDClosure(namespace, &iter.iteratorReverse, "string.iteratorReverse");

		namespace.addList
		(
			"opApply"d,     new MDClosure(namespace, &iter.apply,      "string.opApply"),
			"toInt"d,       new MDClosure(namespace, &lib.toInt,       "string.toInt"),
			"toFloat"d,     new MDClosure(namespace, &lib.toFloat,     "string.toFloat"),
			"compare"d,     new MDClosure(namespace, &lib.compare,     "string.compare"),
			"icompare"d,    new MDClosure(namespace, &lib.icompare,    "string.icompare"),
			"find"d,        new MDClosure(namespace, &lib.find,        "string.find"),
			"ifind"d,       new MDClosure(namespace, &lib.ifind,       "string.ifind"),
			"rfind"d,       new MDClosure(namespace, &lib.rfind,       "string.rfind"),
			"irfind"d,      new MDClosure(namespace, &lib.irfind,      "string.irfind"),
			"toLower"d,     new MDClosure(namespace, &lib.toLower,     "string.toLower"),
			"toUpper"d,     new MDClosure(namespace, &lib.toUpper,     "string.toUpper"),
			"repeat"d,      new MDClosure(namespace, &lib.repeat,      "string.repeat"),
			"split"d,       new MDClosure(namespace, &lib.split,       "string.split"),
			"splitLines"d,  new MDClosure(namespace, &lib.splitLines,  "string.splitLines"),
			"strip"d,       new MDClosure(namespace, &lib.strip,       "string.strip"),
			"lstrip"d,      new MDClosure(namespace, &lib.lstrip,      "string.lstrip"),
			"rstrip"d,      new MDClosure(namespace, &lib.rstrip,      "string.rstrip"),
			"replace"d,     new MDClosure(namespace, &lib.replace,     "string.replace"),
			"startsWith"d,  new MDClosure(namespace, &lib.startsWith,  "string.startsWith"),
			"endsWith"d,    new MDClosure(namespace, &lib.endsWith,    "string.endsWith"),
			"istartsWith"d, new MDClosure(namespace, &lib.istartsWith, "string.istartsWith"),
			"iendsWith"d,   new MDClosure(namespace, &lib.iendsWith,   "string.iendsWith")
		);

		context.globals["string"d] = MDNamespace.create
		(
			"string"d, context.globals.ns,
			"join"d, new MDClosure(context.globals.ns, &lib.join, "string.join")
		);
		
		context.setMetatable(MDValue.Type.String, namespace);
	}

	int toInt(MDState s, uint numParams)
	{
		dchar[] src = s.getContext!(MDString).mData;

		int base = 10;

		if(numParams > 0)
			base = s.getParam!(int)(0);

		s.push(s.safeCode(Integer.toInt(src, base)));
		return 1;
	}

	int toFloat(MDState s, uint numParams)
	{
		s.push(s.safeCode(Float.toFloat(s.getContext!(MDString).mData)));
		return 1;
	}

	int compare(MDState s, uint numParams)
	{
		s.push(s.getContext!(MDString).opCmp(s.getParam!(MDString)(0).mData));
		return 1;
	}

	int icompare(MDState s, uint numParams)
	{
		s.push(idcmp(s.getContext!(MDString).mData, s.getParam!(MDString)(0).mData));
		return 1;
	}

	int find(MDState s, uint numParams)
	{
		dchar[] src = s.getContext!(MDString).mData;
		size_t result;

		if(s.isParam!("string")(0))
			result = Text.locatePattern(src, s.getParam!(MDString)(0).mData);
		else if(s.isParam!("char")(0))
			result = Text.locate(src, s.getParam!(dchar)(0));
		else
			s.throwRuntimeException("Parameter must be string or char");

		if(result == src.length)
			s.push(-1);
		else
			s.push(result);

		return 1;
	}

	int ifind(MDState s, uint numParams)
	{
		dchar[32] buf1, buf2;
		dchar[] src = Uni.toFold(s.getContext!(MDString).mData, buf1);
		size_t result;

		if(s.isParam!("string")(0))
			result = Text.locatePattern(src, Uni.toFold(s.getParam!(MDString)(0).mData, buf2));
		else if(s.isParam!("char")(0))
			result = Text.locate(src, Uni.toFold([s.getParam!(dchar)(0)], buf2)[0]);
		else
			s.throwRuntimeException("Second parameter must be string or int");
			
		if(result == src.length)
			s.push(-1);
		else
			s.push(result);

		return 1;
	}
	
	int rfind(MDState s, uint numParams)
	{
		dchar[] src = s.getContext!(MDString).mData;
		size_t result;

		if(s.isParam!("string")(0))
			result = Text.locatePatternPrior(src, s.getParam!(MDString)(0).mData);
		else if(s.isParam!("char")(0))
			result = Text.locatePrior(src, s.getParam!(dchar)(0));
		else
			s.throwRuntimeException("Second parameter must be string or int");

		if(result == src.length)
			s.push(-1);
		else
			s.push(result);

		return 1;
	}

	int irfind(MDState s, uint numParams)
	{
		dchar[32] buf1, buf2;
		dchar[] src = Uni.toFold(s.getContext!(MDString).mData, buf1);
		size_t result;

		if(s.isParam!("string")(0))
			result = Text.locatePatternPrior(src, Uni.toFold(s.getParam!(MDString)(0).mData, buf2));
		else if(s.isParam!("char")(0))
			result = Text.locatePrior(src, Uni.toFold([s.getParam!(dchar)(0)], buf2)[0]);
		else
			s.throwRuntimeException("Second parameter must be string or int");
			
		if(result == src.length)
			s.push(-1);
		else
			s.push(result);

		return 1;
	}

	int toLower(MDState s, uint numParams)
	{
		MDString src = s.getContext!(MDString);
		dchar[] dest = Uni.toLower(src.mData);

		if(dest is src.mData)
			s.push(src);
		else
			s.push(new MDString(dest));

		return 1;
	}
	
	int toUpper(MDState s, uint numParams)
	{
		MDString src = s.getContext!(MDString);

		dchar[] dest = Uni.toUpper(src.mData);
		
		if(dest is src.mData)
			s.push(src);
		else
			s.push(new MDString(dest));

		return 1;
	}
	
	int repeat(MDState s, uint numParams)
	{
		dchar[] src = s.getContext!(MDString).mData;
		int numTimes = s.getParam!(int)(0);

		if(numTimes < 0)
			s.throwRuntimeException("Invalid number of repetitions: {}", numTimes);

		s.push(Text.repeat(src, numTimes));
		return 1;
	}

	int join(MDState s, uint numParams)
	{
		MDArray array = s.getParam!(MDArray)(0);
		dchar[] sep = s.getParam!(MDString)(1).mData;

		dchar[][] strings = new dchar[][array.length];

		foreach(i, val; array)
		{
			if(!val.isString())
				s.throwRuntimeException("Array element {} is not a string", i);

			strings[i] = val.as!(MDString).mData;
		}

		s.push(Text.join(strings, sep));
		return 1;
	}
	
	int split(MDState s, uint numParams)
	{
		dchar[] src = s.getContext!(MDString).mData;
		dchar[][] ret;

		if(numParams > 0)
			ret = Text.split(src, s.getParam!(MDString)(0).mData);
		else
		{
			ret = Text.delimit(src, " \t\v\r\n\f\u2028\u2029"d);
			uint num = ret.removeIf((dchar[] elem) { return elem.length == 0; });
			ret = ret[0 .. num];
		}

		s.push(MDArray.fromArray(ret));
		return 1;
	}

	int splitLines(MDState s, uint numParams)
	{
		s.push(MDArray.fromArray(Text.splitLines(s.getContext!(MDString).mData)));
		return 1;
	}
	
	int strip(MDState s, uint numParams)
	{
		s.push(Text.trim(s.getContext!(MDString).mData));
		return 1;
	}

	int lstrip(MDState s, uint numParams)
	{
		dchar[] str = s.getContext!(MDString).mData;
		size_t i;

		for(i = 0; i < str.length && Uni.isWhitespace(str[i]); i++){}

		s.push(str[i .. $]);
		return 1;
	}

	int rstrip(MDState s, uint numParams)
	{
		dchar[] str = s.getContext!(MDString).mData;
		int i;

		for(i = str.length - 1; i >= 0 && Uni.isWhitespace(str[i]); i--){}

		s.push(str[0 .. i + 1]);
		return 1;
	}

	int replace(MDState s, uint numParams)
	{
		s.push(Text.substitute(s.getContext!(MDString).mData, s.getParam!(MDString)(0).mData, s.getParam!(MDString)(1).mData));
		return 1;
	}
	
	struct Iterator
	{
		MDClosure iter;
		MDClosure iterReverse;

		int iterator(MDState s, uint numParams)
		{
			MDString string = s.getContext!(MDString);
			int index = s.getParam!(int)(0);

			index++;

			if(index >= string.length)
				return 0;

			s.push(index);
			s.push(string[index]);

			return 2;
		}

		int iteratorReverse(MDState s, uint numParams)
		{
			MDString string = s.getContext!(MDString);
			int index = s.getParam!(int)(0);

			index--;

			if(index < 0)
				return 0;

			s.push(index);
			s.push(string[index]);

			return 2;
		}

		int apply(MDState s, uint numParams)
		{
			MDString string = s.getContext!(MDString);

			if(numParams > 0 && s.isParam!("string")(0) && s.getParam!(MDString)(0) == "reverse"d)
			{
				s.push(iterReverse);
				s.push(string);
				s.push(cast(int)string.length);
			}
			else
			{
				s.push(iter);
				s.push(string);
				s.push(-1);
			}

			return 3;
		}
	}

	int startsWith(MDState s, uint numParams)
	{
		auto string = s.getContext!(MDString);
		auto pattern = s.getParam!(MDString)(0);

		if(pattern.length > string.length)
			s.push(false);
		else
			s.push(string.mData[0 .. pattern.length] == pattern.mData[]);

		return 1;
	}
	
	int endsWith(MDState s, uint numParams)
	{
		auto string = s.getContext!(MDString);
		auto pattern = s.getParam!(MDString)(0);

		if(pattern.length > string.length)
			s.push(false);
		else
			s.push(string.mData[$ - pattern.length .. $] == pattern.mData[]);

		return 1;
	}
	
	int istartsWith(MDState s, uint numParams)
	{
		dchar[32] buf1, buf2;
		auto string = Uni.toFold(s.getContext!(MDString).mData, buf1);
		auto pattern = Uni.toFold(s.getParam!(MDString)(0).mData, buf2);

		if(pattern.length > string.length)
			s.push(false);
		else
			s.push(string[0 .. pattern.length] == pattern[]);

		return 1;
	}

	int iendsWith(MDState s, uint numParams)
	{
		dchar[32] buf1, buf2;
		auto string = Uni.toFold(s.getContext!(MDString).mData, buf1);
		auto pattern = Uni.toFold(s.getParam!(MDString)(0).mData, buf2);

		if(pattern.length > string.length)
			s.push(false);
		else
			s.push(string[$ - pattern.length .. $] == pattern[]);

		return 1;
	}
}