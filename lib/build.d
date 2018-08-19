#!/usr/bin/rdmd
import std.experimental.all;

void main()
{
	chdir(__FILE_FULL_PATH__.dirName);

	auto n = `stb`;
	auto fs = `-I src -DMINIZ_NO_ZLIB_APIS -DMINIZ_NO_ZLIB_COMPATIBLE_NAMES`;

	auto files = `src/console-colors.c src/main.c src/miniz.c src/sqlite3.c`;

	foreach(i, f; files.strip.split(regex(`\s+`)).parallel(1))
	{
		auto res = format(`gcc -c -o tmp_%d.o %s %s -w -fPIC -fomit-frame-pointer -O3 -mfpmath=sse -msse3 -DNDEBUG`, i, f, fs).executeShell;

		if(res.status)
		{
			res.output.writeln;
		}
	}

	executeShell(`ar rcs lib` ~ n ~ `_x64.a tmp_*.o`);
	executeShell(`rm -rf tmp_*.o`);
}
