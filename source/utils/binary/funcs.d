module utils.binary.funcs;

import
		std.mmfile,

		utils.except,
		utils.binary;

// ----------------------------------------- READ FUNCTIONS -----------------------------------------

auto binaryRead(T)(in void[] data, bool canRest = false, string f = __FILE__, uint l = __LINE__)
{
	auto r = data.BinaryReader!MemoryReader;
	auto v = r.read!T(f, l);

	!r.reader.length || canRest || throwError!`not all the buffer was parsed, %s bytes rest`(f, l, r.reader.length);
	return v;
}

auto binaryReadFile(T)(string name, string f = __FILE__, uint l = __LINE__)
{
	auto m = new MmFile(name);

	try
	{
		return m[].binaryRead!T(false, f, l);
	}
	finally
	{
		m.destroy;
	}
}

// ----------------------------------------- WRITE FUNCTIONS -----------------------------------------

const(void)[] binaryWrite(T)(auto ref in T data, string f = __FILE__, uint l = __LINE__)
{
	return BinaryReader!AppendWriter().write(data, f, l).reader.data;
}

void binaryWrite(T)(void[] buf, auto ref in T data, bool canRest = false, string f = __FILE__, uint l = __LINE__)
{
	auto r = buf.BinaryReader!MemoryReader;
	r.write(data, f, l);

	!r.reader.length || canRest || throwError!`not all the buffer was used, %u bytes rest`(f, l, r.reader.length);
}

void binaryWriteFile(T)(string name, auto ref in T data, string f = __FILE__, uint l = __LINE__)
{
	auto len = binaryWriteLen(data, f, l);
	auto m = new MmFile(name, MmFile.Mode.readWriteNew, len, null);

	try
	{
		binaryWrite(m[], data, false, f, l);
	}
	finally
	{
		m.destroy;
	}
}

// ----------------------------------------- OTHER FUNCTIONS -----------------------------------------

auto binaryWriteLen(T)(auto ref in T data, string f = __FILE__, uint l = __LINE__)
{
	struct LengthCalc
	{
		bool write(in ubyte[] v)
		{
			length += v.length;
			return true;
		}

		bool wskip(uint cnt)
		{
			length += cnt;
			return true;
		}

		uint length;
	}

	return BinaryReader!LengthCalc().write(data, f, l).reader.length;
}
