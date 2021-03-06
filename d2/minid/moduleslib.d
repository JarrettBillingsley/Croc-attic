/******************************************************************************
This module contains the 'modules' standard library, which is part of the
base library.

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

module minid.moduleslib;

import std.file;
import std.path;
import std.string;

import minid.compiler;
import minid.ex;
import minid.interpreter;
import minid.serialization;
import minid.types;

struct ModulesLib
{
static:
	public void init(MDThread* t)
	{
		newTable(t); setRegistryVar(t, "modules.loading");

		auto ns = newNamespace(t, "modules");
			pushString(t, "."); fielda(t, ns, "path");
			newTable(t);        fielda(t, ns, "customLoaders");
			dup(t, ns); newFunctionWithEnv(t, &load,       "load");       fielda(t, ns, "load");
			dup(t, ns); newFunctionWithEnv(t, &reload,     "reload");     fielda(t, ns, "reload");
			dup(t, ns); newFunctionWithEnv(t, &initModule, "initModule"); fielda(t, ns, "initModule");
			dup(t, ns); newFunctionWithEnv(t, &runMain,    "runMain");    fielda(t, ns, "runMain");
			dup(t, ns); newFunctionWithEnv(t, &compile,    "compile");    fielda(t, ns, "compile");

			newTable(t);
				// integrate 'modules' itself into the module loading system
				dup(t, ns);
				fielda(t, -2, "modules");
			fielda(t, ns, "loaded");

			pushString(t, "loaders");
				dup(t, ns); newFunctionWithEnv(t, &customLoad,    "customLoad");
				dup(t, ns); newFunctionWithEnv(t, &checkTaken,    "checkTaken");
				dup(t, ns); newFunctionWithEnv(t, &loadFiles,     "loadFiles");

				version(MDDynLibs)
				{
					dup(t, ns); newFunctionWithEnv(t, &loadDynlib, "loadDynlib");
					newArrayFromStack(t, 4);
				}
				else
					newArrayFromStack(t, 3);
			fielda(t, ns);
		newGlobal(t, "modules");
	}

	package uword load(MDThread* t, uword numParams)
	{
		auto name = checkStringParam(t, 1);

		pushGlobal(t, "loaded");
		dup(t, 1);
		idx(t, -2);

		if(isNamespace(t, -1))
			return 1;

		pop(t, 2);
		return commonLoad(t, name);
	}

	package uword reload(MDThread* t, uword numParams)
	{
		auto name = checkStringParam(t, 1);

		pushGlobal(t, "loaded");
		dup(t, 1);
		idx(t, -2);

		if(isNull(t, -1))
			throwException(t, "Attempting to reload module '{}' which has not yet been loaded", name);

		pop(t, 2);
		return commonLoad(t, name);
	}

	package uword commonLoad(MDThread* t, string name)
	{
		checkCircular(t, name);

		scope(exit)
		{
			getRegistryVar(t, "modules.loading");
			pushNull(t);
			fielda(t, -2, name);
			pop(t);
		}

		auto loaders = pushGlobal(t, "loaders");
		auto num = len(t, -1);

		for(uword i = 0; i < num; i++)
		{
			auto reg = pushInt(t, i);
			idx(t, loaders);
			pushNull(t);
			pushString(t, name);
			rawCall(t, reg, 1);

			if(isFunction(t, -1))
			{
				pushGlobal(t, "initModule");
				swap(t);
				pushNull(t);
				swap(t);
				pushString(t, name);
				return rawCall(t, -4, 1);
			}
			else if(isNamespace(t, -1))
			{
				pushGlobal(t, "loaded");
				pushString(t, name);

				if(!opin(t, -1, -2))
				{
					dup(t, -3);
					idxa(t, -3);
					pop(t);
				}
				else
					pop(t, 2);

				return 1;
			}

			pop(t);
		}

		throwException(t, "Error loading module '{}': could not find anything to load", name);
		assert(false);
	}

	package uword initModule(MDThread* t, uword numParams)
	{
		checkParam(t, 1, MDValue.Type.Function);
		auto name = checkStringParam(t, 2);

		// Make the namespace
		pushGlobal(t, "_G");

		foreach(segment; name.split(".")) // TODO: in-place splitting
		{
			pushString(t, segment);

			if(opin(t, -1, -2))
			{
				field(t, -2);

				if(!isNamespace(t, -1))
					throwException(t, "Error loading module \"{}\": conflicts with existing global", name);
			}
			else
			{
				pop(t);
				newNamespace(t, -1, segment);
				dup(t);
				fielda(t, -3, segment);
			}

			insertAndPop(t, -2);
		}

		if(len(t, -1) > 0)
			clearNamespace(t, -1);

		// Set the environment (also used as 'this')
		dup(t, 1);
		dup(t, -2);
		dup(t);
		setFuncEnv(t, -3);

		// Call it with the name as the first param
		pushString(t, name);
		rawCall(t, -3, 0);

		// Add it to the loaded table
		pushGlobal(t, "loaded");
		pushString(t, name);
		dup(t, -3);
		idxa(t, -3);
		pop(t);

		return 1;
	}

	uword runMain(MDThread* t, uword numParams)
	{
		checkParam(t, 1, MDValue.Type.Namespace);

		if(hasField(t, 1, "main"))
		{
			auto main = field(t, 1, "main");

			if(isFunction(t, main))
			{
				insert(t, 1);
				rawCall(t, 1, 0);
			}
		}

		return 0;
	}

	uword compile(MDThread* t, uword numParams)
	{
		auto src = checkStringParam(t, 1);
		auto name = optStringParam(t, 2, "<loaded by modules.compile>");
		scope c = new Compiler(t);
		c.compileModule(src, name);
		return 1;
	}

	package uword customLoad(MDThread* t, uword numParams)
	{
		checkStringParam(t, 1);
		pushGlobal(t, "customLoaders");
		dup(t, 1);
		idx(t, -2);

		if(isFunction(t, -1) || isNamespace(t, -1))
			return 1;

		return 0;
	}

	package uword checkTaken(MDThread* t, uword numParams)
	{
		auto name = checkStringParam(t, 1);

		pushGlobal(t, "_G");

		foreach(segment; name.split(".")) // TODO: in-place split
		{
			pushString(t, segment);

			if(opin(t, -1, -2))
			{
				field(t, -2);

				if(!isNamespace(t, -1))
					throwException(t, "Error loading module \"{}\": conflicts with existing global", name);

				insertAndPop(t, -2);
			}
			else
				return 0;
		}

		return 0;
	}

	package uword loadFiles(MDThread* t, uword numParams)
	{
		auto name = checkStringParam(t, 1);
		auto pos = name.lastIndexOf('.');
		string packages;
		string modName;

		if(pos == -1)
		{
			packages = "";
			modName = name;
		}
		else
		{
			packages = name[0 .. pos];
			modName = name[pos + 1 .. $];
		}
	
		// safe since this string is held in the modules namespace
		pushGlobal(t, "path");
		auto paths = getString(t, -1);
		pop(t);
	
		outerLoop: foreach(path; paths.split(";")) // TODO: in-place split
		{
			// TODO: try to make this not allocate memory?  Is this possible?
			if(!exists(path))
				continue;

			foreach(piece; packages.split(".")) // TODO: in-place split
			{
				path = join(path, piece);

				if(!exists(path))
					continue outerLoop;
			}
	
			auto src = join(path, modName ~ ".md");
			auto bin = join(path, modName ~ ".mdm");

			if(exists(src))
			{
				if(exists(bin))
				{
					if(lastModified(src) > lastModified(bin))
					{
						scope c = new Compiler(t);
						c.compileModule(src);
						return 1;
					}
					else
					{
						// TODO
						assert(false);
// 						scope fc = new File(bin.toString(), File.ReadExisting);
// 						deserializeModule(t, fc);
// 						return 1;
					}
				}
				else
				{
					scope c = new Compiler(t);
					c.compileModule(src);
					return 1;
				}
			}
			else if(exists(bin))
			{
				// TODO
				assert(false);
// 				scope fc = new File(bin.toString(), File.ReadExisting);
// 				deserializeModule(t, fc);
// 				return 1;
			}
		}

		return 0;
	}

	private void checkCircular(MDThread* t, string name)
	{
		getRegistryVar(t, "modules.loading");
		field(t, -1, name);

		if(!isNull(t, -1))
			throwException(t, "Attempting to import module \"{}\" while it's in the process of being imported; is it being circularly imported?", name);

		pop(t);
		pushBool(t, true);
		fielda(t, -2, name);
		pop(t);
	}
}