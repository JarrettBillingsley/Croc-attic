// NOTE TO SELF: This does not run successfully with -cov enabled in the host.  Causes a Heisenbug.
module tests.iando;

io.changeDir(`tests\files`);

io.File("foo", io.FileMode.OutNew).close();
io.rename("foo", "bar");
io.copy("bar", "foo");
io.size("foo");
io.exists("foo");
io.isFile("foo");
io.isDir("bar");
io.currentDir();
io.makeDir("dir");
io.removeDir("dir");
io.listFiles(io.currentDir());
io.listFiles(io.currentDir(), "*.md");
io.listDirs(io.currentDir());
io.listDirs(io.currentDir(), "*x");

local f = io.File("foo");
try io.File("FOASAF"); catch(e){}
f.seek(0, 'c');
f.seek(0, 'e');
f.seek(0, 'b');
try f.seek(0, 'n'); catch(e){}
f.position();
f.position(0);
f.size();
f.close();

f = io.File("foo", io.FileMode.In | io.FileMode.Out);
f.isOpen();
f.writeInt(4);
f.writeString("hi");
f.write("hi ");
f.writeln("hello");
f.writef("bye");
f.writefln("foo");
f.writeChars("xyz");
f.writeJSON({});
f.writeJSON([], true);
f.flush();
f.position(0);
f.output().writeInt(4);
f.output().writeString("hi");
f.output().write("hi ");
f.output().writeln("hello");
f.output().writef("bye");
f.output().writefln("foo");
f.output().writeChars("xyz");
f.output().writeJSON({});
f.output().writeJSON([], true);
f.output().flush();
f.position(0);
f.position();
f.readInt();
f.readString();
f.readln();
// f.readf("%s");
f.readChars(1);
f.position(0);
f.input().readInt();
f.input().readString();
f.input().readln();
f.input().readChars(1);
f.close();

f = io.File("lines.txt");
foreach(line; f){}
f.close();
f = io.File("lines.txt");
foreach(line; f.input()){}
f.close();

io.remove("foo");
io.remove("bar");
io.changeDir(`..\..`);