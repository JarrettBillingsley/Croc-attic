/******************************************************************************
This module contains internal implementation of the function object.

License:
Copyright (c) 2008 Jarrett Billingsley

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

module minid.func;

import minid.alloc;
import minid.types;

struct func
{
static:
	// ================================================================================================================================================
	// Package
	// ================================================================================================================================================

	// Create a script function.
	package MDFunction* create(ref Allocator alloc, MDNamespace* env, MDFuncDef* def)
	{
		auto f = alloc.allocate!(MDFunction)(ScriptClosureSize(def.numUpvals));
		f.isNative = false;
		f.environment = env;
		f.name = def.name;
		f.numUpvals = def.numUpvals;

		f.scriptFunc = def;
		f.scriptUpvals()[] = null;

		return f;
	}

	// Create a native function.
	package MDFunction* create(ref Allocator alloc, MDNamespace* env, MDString* name, NativeFunc func, uword numUpvals)
	{
		auto f = alloc.allocate!(MDFunction)(NativeClosureSize(numUpvals));
		f.isNative = true;
		f.environment = env;
		f.name = name;
		f.numUpvals = numUpvals;

		f.nativeFunc = func;
		f.nativeUpvals()[] = MDValue.nullValue;

		return f;
	}

	// Free a function.
	package void free(ref Allocator alloc, MDFunction* f)
	{
		if(f.isNative)
			alloc.free(f, NativeClosureSize(f.numUpvals));
		else
			alloc.free(f, ScriptClosureSize(f.numUpvals));
	}

	package bool isNative(MDFunction* f)
	{
		return f.isNative;
	}

	package word numParams(MDFunction* f)
	{
		if(f.isNative)
			return 0;
		else
			return f.scriptFunc.numParams;
	}

	package bool isVararg(MDFunction* f)
	{
		if(f.isNative)
			return true;
		else
			return f.scriptFunc.isVararg;
	}

	package uword ScriptClosureSize(uword numUpvals)
	{
		return MDFunction.sizeof + ((MDUpval*).sizeof * numUpvals);
	}

	package uword NativeClosureSize(uword numUpvals)
	{
		return MDFunction.sizeof + (MDValue.sizeof * numUpvals);
	}
}