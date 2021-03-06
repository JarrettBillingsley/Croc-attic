/******************************************************************************
This module contains the 'io' standard library.

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

module minid.iolib;

// import Path = tango.io.Path;
// import tango.io.device.File;
// import tango.io.stream.Buffered;
// import tango.io.UnicodeFile;
// import tango.sys.Environment;
// import tango.time.WallClock;
// import tango.time.Time;

import minid.ex;
import minid.interpreter;
// import minid.streamlib;
import minid.timelib;
import minid.types;
import minid.vector;

struct IOLib
{
static:
	public void init(MDThread* t)
	{
		makeModule(t, "io", function uword(MDThread* t, uword numParams)
		{
			importModuleNoNS(t, "stream");

			lookup(t, "stream.stdin");
			newGlobal(t, "stdin");

			lookup(t, "stream.stdout");
			newGlobal(t, "stdout");

			lookup(t, "stream.stderr");
			newGlobal(t, "stderr");

			newFunction(t, &inFile,                "inFile");       newGlobal(t, "inFile");
			newFunction(t, &outFile,               "outFile");      newGlobal(t, "outFile");
			newFunction(t, &inoutFile,             "inoutFile");    newGlobal(t, "inoutFile");
			newFunction(t, &rename,                "rename");       newGlobal(t, "rename");
			newFunction(t, &remove,                "remove");       newGlobal(t, "remove");
			newFunction(t, &copy,                  "copy");         newGlobal(t, "copy");
			newFunction(t, &size,                  "size");         newGlobal(t, "size");
			newFunction(t, &exists,                "exists");       newGlobal(t, "exists");
			newFunction(t, &isFile,                "isFile");       newGlobal(t, "isFile");
			newFunction(t, &isDir,                 "isDir");        newGlobal(t, "isDir");
			newFunction(t, &isReadOnly,            "isReadOnly");   newGlobal(t, "isReadOnly");
			newFunction(t, &fileTime!("modified"), "modified");     newGlobal(t, "modified");
			newFunction(t, &fileTime!("created"),  "created");      newGlobal(t, "created");
			newFunction(t, &fileTime!("accessed"), "accessed");     newGlobal(t, "accessed");
			newFunction(t, &currentDir,            "currentDir");   newGlobal(t, "currentDir");
			newFunction(t, &parentDir,             "parentDir");    newGlobal(t, "parentDir");
			newFunction(t, &changeDir,             "changeDir");    newGlobal(t, "changeDir");
			newFunction(t, &makeDir,               "makeDir");      newGlobal(t, "makeDir");
			newFunction(t, &makeDirChain,          "makeDirChain"); newGlobal(t, "makeDirChain");
			newFunction(t, &removeDir,             "removeDir");    newGlobal(t, "removeDir");
			newFunction(t, &listFiles,             "listFiles");    newGlobal(t, "listFiles");
			newFunction(t, &listDirs,              "listDirs");     newGlobal(t, "listDirs");
			newFunction(t, &readFile,              "readFile");     newGlobal(t, "readFile");
			newFunction(t, &writeFile,             "writeFile");    newGlobal(t, "writeFile");
			newFunction(t, &readVector,            "readVector");   newGlobal(t, "readVector");
			newFunction(t, &writeVector,           "writeVector");  newGlobal(t, "writeVector");
			newFunction(t, &join,                  "join");         newGlobal(t, "join");
			newFunction(t, &dirName,               "dirName");      newGlobal(t, "dirName");
			newFunction(t, &name,                  "name");         newGlobal(t, "name");
			newFunction(t, &extension,             "extension");    newGlobal(t, "extension");
			newFunction(t, &fileName,              "fileName");     newGlobal(t, "fileName");

				newFunction(t, &linesIterator, "linesIterator");
			newFunction(t, &lines, "lines", 1);        newGlobal(t, "lines");

			return 0;
		});

		importModuleNoNS(t, "io");
	}

	uword inFile(MDThread* t, uword numParams)
	{
		auto name = checkStringParam(t, 1);
		auto f = safeCode(t, new BufferedInput(new File(name, File.ReadExisting)));

		lookupCT!("stream.InStream")(t);
		pushNull(t);
		pushNativeObj(t, f);
		rawCall(t, -3, 1);

		return 1;
	}

	uword outFile(MDThread* t, uword numParams)
	{
		auto name = checkStringParam(t, 1);
		auto mode = optCharParam(t, 2, 'c');

		File.Style style;

		switch(mode)
		{
			case 'e': style = File.WriteExisting;  break;
			case 'a': style = File.WriteAppending; break;
			case 'c': style = File.WriteCreate;    break;
			default:
				throwException(t, "Unknown open mode '{}'", mode);
		}

		auto f = safeCode(t, new BufferedOutput(new File(name, style)));

		lookupCT!("stream.OutStream")(t);
		pushNull(t);
		pushNativeObj(t, f);
		rawCall(t, -3, 1);

		return 1;
	}

	uword inoutFile(MDThread* t, uword numParams)
	{
		static const File.Style ReadWriteAppending = { File.Access.ReadWrite, File.Open.Append };

		auto name = checkStringParam(t, 1);
		auto mode = optCharParam(t, 2, 'e');

		File.Style style;

		switch(mode)
		{
			case 'e': style = File.ReadWriteExisting; break;
			case 'a': style = ReadWriteAppending;     break;
			case 'c': style = File.ReadWriteCreate;   break;
			default:
				throwException(t, "Unknown open mode '{}'", mode);
		}

		// TODO: figure out some way of making inout files buffered?
		auto f = safeCode(t, new File(name, style));

		lookupCT!("stream.InoutStream")(t);
		pushNull(t);
		pushNativeObj(t, f);
		rawCall(t, -3, 1);

		return 1;
	}

	uword rename(MDThread* t, uword numParams)
	{
		safeCode(t, Path.rename(checkStringParam(t, 1), checkStringParam(t, 2)));
		return 0;
	}

	uword remove(MDThread* t, uword numParams)
	{
		safeCode(t, Path.remove(checkStringParam(t, 1)));
		return 0;
	}

	uword copy(MDThread* t, uword numParams)
	{
		safeCode(t, Path.copy(checkStringParam(t, 1), checkStringParam(t, 2)));
		return 0;
	}

	uword size(MDThread* t, uword numParams)
	{
		pushInt(t, cast(mdint)safeCode(t, Path.fileSize(checkStringParam(t, 1))));
		return 1;
	}

	uword exists(MDThread* t, uword numParams)
	{
		pushBool(t, Path.exists(checkStringParam(t, 1)));
		return 1;
	}

	uword isFile(MDThread* t, uword numParams)
	{
		pushBool(t, safeCode(t, !Path.isFolder(checkStringParam(t, 1))));
		return 1;
	}

	uword isDir(MDThread* t, uword numParams)
	{
		pushBool(t, safeCode(t, Path.isFolder(checkStringParam(t, 1))));
		return 1;
	}
	
	uword isReadOnly(MDThread* t, uword numParams)
	{
		pushBool(t, safeCode(t, !Path.isWritable(checkStringParam(t, 1))));
		return 1;
	}

	uword fileTime(char[] which)(MDThread* t, uword numParams)
	{
		auto time = safeCode(t, mixin("Path." ~ which ~ "(checkStringParam(t, 1))"));
		word tab;

		if(numParams == 1)
			tab = newTable(t);
		else
		{
			checkParam(t, 2, MDValue.Type.Table);
			tab = 2;
		}

		TimeLib.DateTimeToTable(t, WallClock.toDate(time), tab);
		dup(t, tab);
		return 1;
	}

	uword currentDir(MDThread* t, uword numParams)
	{
		pushString(t, safeCode(t, Environment.cwd()));
		return 1;
	}
	
	uword parentDir(MDThread* t, uword numParams)
	{
		auto p = optStringParam(t, 1, ".");
		
		if(p == ".")
			p = Environment.cwd();

		auto pp = safeCode(t, Path.parse(p));

		if(pp.isAbsolute)
			pushString(t, safeCode(t, Path.pop(p)));
		else
			pushString(t, safeCode(t, Path.join(Environment.cwd(), p)));

		return 1;
	}

	uword changeDir(MDThread* t, uword numParams)
	{
		safeCode(t, Environment.cwd(checkStringParam(t, 1)));
		return 0;
	}

	uword makeDir(MDThread* t, uword numParams)
	{
		auto p = Path.parse(checkStringParam(t, 1));

		if(!p.isAbsolute())
			safeCode(t, Path.createFolder(Path.join(Environment.cwd(), p.toString())));
		else
			safeCode(t, Path.createFolder(p.toString()));

		return 0;
	}

	uword makeDirChain(MDThread* t, uword numParams)
	{
		auto p = Path.parse(checkStringParam(t, 1));
		
		if(!p.isAbsolute())
			safeCode(t, Path.createPath(Path.join(Environment.cwd(), p.toString())));
		else
			safeCode(t, Path.createPath(p.toString()));

		return 0;
	}

	uword removeDir(MDThread* t, uword numParams)
	{
		safeCode(t, Path.remove(checkStringParam(t, 1)));
		return 0;
	}
	
	uword listImpl(MDThread* t, uword numParams, bool isFolder)
	{
		auto fp = optStringParam(t, 1, ".");
		
		if(fp == ".")
			fp = Environment.cwd();

		auto listing = newArray(t, 0);

		if(numParams >= 2)
		{
			auto filter = checkStringParam(t, 2);

			safeCode(t,
			{
				foreach(ref info; Path.children(fp))
				{
					if(info.folder is isFolder)
					{
						pushString(t, info.path);
						pushString(t, info.name);
						cat(t, 2);
						auto fullName = getString(t, -1);
	
						if(Path.patternMatch(fullName, filter))
							cateq(t, listing, 1);
						else
							pop(t);
					}
				}
			}());
		}
		else
		{
			safeCode(t,
			{
				foreach(ref info; Path.children(fp))
				{
					if(info.folder is isFolder)
					{
						pushString(t, info.path);
						pushString(t, info.name);
						cat(t, 2);
						cateq(t, listing, 1);
					}
				}
			}());
		}

		return 1;
	}

	uword listFiles(MDThread* t, uword numParams)
	{
		return listImpl(t, numParams, false);
	}

	uword listDirs(MDThread* t, uword numParams)
	{
		return listImpl(t, numParams, true);
	}

	uword readFile(MDThread* t, uword numParams)
	{
		auto name = checkStringParam(t, 1);
		auto shouldConvert = optBoolParam(t, 2, false);

		if(shouldConvert)
		{
			safeCode(t,
			{
				auto data = cast(ubyte[]).File.get(name);

				scope(exit)
					delete data;

				foreach(ref c; data)
					if(c > 0x7f)
						c = '?';

				pushString(t, cast(char[])data);
			}());
		}
		else
		{
			safeCode(t,
			{
				scope file = new UnicodeFile!(char)(name, Encoding.Unknown);
				pushString(t, file.read());
			}());
		}

		return 1;
	}

	uword writeFile(MDThread* t, uword numParams)
	{
		auto name = checkStringParam(t, 1);
		auto data = checkStringParam(t, 2);

		safeCode(t,
		{
			scope file = new UnicodeFile!(char)(name, Encoding.UTF_8N);
			file.write(data, true);
		}());

		return 0;
	}
	
	uword readVector(MDThread* t, uword numParams)
	{
		auto name = checkStringParam(t, 1);
		auto size = safeCode(t, Path.fileSize(name));

		if(size > uword.max)
			throwException(t, "file too big ({} bytes)", size);

		pushGlobal(t, "Vector");
		pushNull(t);
		pushString(t, "u8");
		pushInt(t, cast(mdint)size);
		rawCall(t, -4, 1);
		auto memb = getMembers!(VectorObj.Members)(t, -1);

		safeCode(t, File.get(name, memb.data[0 .. cast(uword)size]));

		return 1;
	}

	uword writeVector(MDThread* t, uword numParams)
	{
		auto name = checkStringParam(t, 1);
		auto memb = checkInstParam!(VectorObj.Members)(t, 2, "Vector");
		auto data = memb.data[0 .. memb.length * memb.type.itemSize];

		safeCode(t, File.set(name, data));

		return 1;
	}

	uword linesIterator(MDThread* t, uword numParams)
	{
		auto lines = checkInstParam!(InStreamObj.Members)(t, 0, "stream.InStream").lines;
		auto index = checkIntParam(t, 1) + 1;
		auto line = safeCode(t, lines.next());

		if(line.ptr is null)
		{
			dup(t, 0);
			pushNull(t);
			methodCall(t, -2, "close", 0);
			return 0;
		}

		pushInt(t, index);
		pushString(t, line);
		return 2;
	}

	uword lines(MDThread* t, uword numParams)
	{
		checkStringParam(t, 1);

		pushGlobal(t, "inFile");
		pushNull(t);
		dup(t, 1);
		rawCall(t, -3, 1);

		pushInt(t, 0);
		getUpval(t, 0);
		insert(t, -3);

		return 3;
	}

	uword join(MDThread* t, uword numParams)
	{
		checkAnyParam(t, 1);
		
		char[][] tmp;

		scope(exit)
			delete tmp;

		for(uword i = 1; i <= numParams; i++)
			tmp ~= checkStringParam(t, i);

		pushString(t, safeCode(t, Path.join(tmp)));
		return 1;
	}
	
	uword dirName(MDThread* t, uword numParams)
	{
		pushString(t, safeCode(t, Path.parse(checkStringParam(t, 1))).path);
		return 1;
	}

	uword name(MDThread* t, uword numParams)
	{
		pushString(t, safeCode(t, Path.parse(checkStringParam(t, 1))).name);
		return 1;
	}

	uword extension(MDThread* t, uword numParams)
	{
		pushString(t, safeCode(t, Path.parse(checkStringParam(t, 1))).ext);
		return 1;
	}

	uword fileName(MDThread* t, uword numParams)
	{
		pushString(t, safeCode(t, Path.parse(checkStringParam(t, 1))).file);
		return 1;
	}
}