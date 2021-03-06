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

module minid.mathlib;

import minid.types;
import minid.utils;

import math = tango.math.Math;
import tango.math.GammaFunction;
import tango.math.random.Kiss;
import tango.math.IEEE;

class MathLib
{
	private static MathLib lib;
	
	static this()
	{
		lib = new MathLib();
	}
	
	private this()
	{
		
	}

	public static void init(MDContext context)
	{
		MDNamespace namespace = new MDNamespace("math"d, context.globals.ns);

		namespace.addList
		(
			"e"d,         tango.math.Math.E,
			"pi"d,        tango.math.Math.PI,
			"nan"d,       mdfloat.nan,
			"infinity"d,  mdfloat.infinity,
			"int_min"d,   int.min,
			"int_max"d,   int.max,
			"float_min"d, mdfloat.min,
			"float_max"d, mdfloat.max,
			"abs"d,       new MDClosure(namespace, &lib.abs,     "math.abs"),
			"sin"d,       new MDClosure(namespace, &lib.sin,     "math.sin"),
			"cos"d,       new MDClosure(namespace, &lib.cos,     "math.cos"),
			"tan"d,       new MDClosure(namespace, &lib.tan,     "math.tan"),
			"asin"d,      new MDClosure(namespace, &lib.asin,    "math.asin"),
			"acos"d,      new MDClosure(namespace, &lib.acos,    "math.acos"),
			"atan"d,      new MDClosure(namespace, &lib.atan,    "math.atan"),
			"atan2"d,     new MDClosure(namespace, &lib.atan2,   "math.atan2"),
			"sqrt"d,      new MDClosure(namespace, &lib.sqrt,    "math.sqrt"),
			"cbrt"d,      new MDClosure(namespace, &lib.cbrt,    "math.cbrt"),
			"pow"d,       new MDClosure(namespace, &lib.pow,     "math.pow"),
			"exp"d,       new MDClosure(namespace, &lib.exp,     "math.exp"),
			"ln"d,        new MDClosure(namespace, &lib.ln,      "math.ln"),
			"log2"d,      new MDClosure(namespace, &lib.log2,    "math.log2"),
			"log10"d,     new MDClosure(namespace, &lib.log10,   "math.log10"),
			"hypot"d,     new MDClosure(namespace, &lib.hypot,   "math.hypot"),
			"lgamma"d,    new MDClosure(namespace, &lib.lgamma,  "math.lgamma"),
			"gamma"d,     new MDClosure(namespace, &lib.gamma,   "math.gamma"),
			"ceil"d,      new MDClosure(namespace, &lib.ceil,    "math.ceil"),
			"floor"d,     new MDClosure(namespace, &lib.floor,   "math.floor"),
			"round"d,     new MDClosure(namespace, &lib.round,   "math.round"),
			"trunc"d,     new MDClosure(namespace, &lib.trunc,   "math.trunc"),
			"isNan"d,     new MDClosure(namespace, &lib.isNan,   "math.isNan"),
			"isInf"d,     new MDClosure(namespace, &lib.isInf,   "math.isInf"),
			"sign"d,      new MDClosure(namespace, &lib.sign,    "math.sign"),
			"rand"d,      new MDClosure(namespace, &lib.rand,    "math.rand"),
			"frand"d,     new MDClosure(namespace, &lib.frand,   "math.frand")
		);
		
		context.globals["math"d] = namespace;
	}

	static mdfloat getFloat(MDState s, uint i)
	{
		if(s.isParam!("int")(i))
			return s.getParam!(int)(i);
		else if(s.isParam!("float")(i))
			return s.getParam!(mdfloat)(i);
		else
			s.throwRuntimeException("Expected 'int' or 'float', not '{}'", s.getParam(i).typeString());
	}

	int abs(MDState s, uint numParams)
	{
		if(s.isParam!("int")(0))
			s.push(math.abs(s.getParam!(int)(0)));
		else if(s.isParam!("float")(0))
			s.push(math.abs(s.getParam!(mdfloat)(0)));
		else
			s.throwRuntimeException("Expected 'int' or 'float', not '{}'", s.getParam(0u).typeString());

		return 1;
	}
	
	int sin(MDState s, uint numParams)
	{
		s.push(math.sin(getFloat(s, 0)));
		return 1;
	}
	
	int cos(MDState s, uint numParams)
	{
		s.push(math.cos(getFloat(s, 0)));
		return 1;
	}
	
	int tan(MDState s, uint numParams)
	{
		s.push(math.tan(getFloat(s, 0)));
		return 1;
	}
	
	int asin(MDState s, uint numParams)
	{
		s.push(math.asin(getFloat(s, 0)));
		return 1;
	}
	
	int acos(MDState s, uint numParams)
	{
		s.push(math.acos(getFloat(s, 0)));
		return 1;
	}
	
	int atan(MDState s, uint numParams)
	{
		s.push(math.atan(getFloat(s, 0)));
		return 1;
	}
	
	int atan2(MDState s, uint numParams)
	{
		s.push(math.atan2(getFloat(s, 0), getFloat(s, 1)));
		return 1;
	}
	
	int sqrt(MDState s, uint numParams)
	{
		s.push(math.sqrt(getFloat(s, 0)));
		return 1;
	}
	
	int cbrt(MDState s, uint numParams)
	{
		s.push(math.cbrt(getFloat(s, 0)));
		return 1;
	}
	
	int exp(MDState s, uint numParams)
	{
		s.push(math.exp(getFloat(s, 0)));
		return 1;
	}
	
	int ln(MDState s, uint numParams)
	{
		s.push(math.log(getFloat(s, 0)));
		return 1;
	}
	
	int log2(MDState s, uint numParams)
	{
		s.push(math.log2(getFloat(s, 0)));
		return 1;
	}
	
	int log10(MDState s, uint numParams)
	{
		s.push(math.log10(getFloat(s, 0)));
		return 1;
	}
	
	int hypot(MDState s, uint numParams)
	{
		s.push(math.hypot(getFloat(s, 0), getFloat(s, 1)));
		return 1;
	}
	
	int lgamma(MDState s, uint numParams)
	{
		s.push(logGamma(getFloat(s, 0)));
		return 1;
	}

	int gamma(MDState s, uint numParams)
	{
		s.push(.gamma(getFloat(s, 0)));
		return 1;
	}
	
	int ceil(MDState s, uint numParams)
	{
		s.push(math.ceil(getFloat(s, 0)));
		return 1;
	}
	
	int floor(MDState s, uint numParams)
	{
		s.push(math.floor(getFloat(s, 0)));
		return 1;
	}
	
	int round(MDState s, uint numParams)
	{
		s.push(cast(int)math.round(getFloat(s, 0)));
		return 1;
	}
	
	int trunc(MDState s, uint numParams)
	{
		s.push(cast(int)math.trunc(getFloat(s, 0)));
		return 1;
	}
	
	int isNan(MDState s, uint numParams)
	{
		s.push(cast(bool)math.isNaN(getFloat(s, 0)));
		return 1;
	}

	int isInf(MDState s, uint numParams)
	{
		s.push(cast(bool)math.isInfinity(getFloat(s, 0)));
		return 1;
	}
	
	int sign(MDState s, uint numParams)
	{
		if(s.isParam!("int")(0))
		{
			int val = s.getParam!(int)(0);

			if(val < 0)
				s.push(-1);
			else if(val > 0)
				s.push(1);
			else
				s.push(0);
		}
		else
		{
			mdfloat val = s.getParam!(mdfloat)(0);

			if(val < 0)
				s.push(-1);
			else if(val > 0)
				s.push(1);
			else
				s.push(0);
		}
		
		return 1;
	}
	
	int pow(MDState s, uint numParams)
	{
		mdfloat base = getFloat(s, 0);
		
		if(s.isParam!("int")(1))
			s.push(math.pow(cast(real)base, s.getParam!(int)(1)));
		else
			s.push(math.pow(base, getFloat(s, 1)));
			
		return 1;
	}

	int rand(MDState s, uint numParams)
	{
		uint num = Kiss.shared.toInt();

		switch(numParams)
		{
			case 0:
				s.push(cast(int)num);
				break;

			case 1:
				s.push(cast(uint)num % s.getParam!(int)(0));
				break;

			default:
				int lo = s.getParam!(int)(0);
				int hi = s.getParam!(int)(1);

				s.push(cast(int)(num % (hi - lo)) + lo);
				break;
		}

		return 1;
	}

	int frand(MDState s, uint numParams)
	{
		auto num = cast(mdfloat)Kiss.shared.toInt() / uint.max;

		switch(numParams)
		{
			case 0:
				s.push(num);
				break;

			case 1:
				s.push(num * s.getParam!(mdfloat)(0));
				break;

			default:
				auto lo = s.getParam!(mdfloat)(0);
				auto hi = s.getParam!(mdfloat)(1);

				s.push((num * (hi - lo)) + lo);
				break;
		}
		
		return 1;
	}
}