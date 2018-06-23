module utils.binary.readers;

import
		utils.misc;


struct MemoryReader
{
	this(in void[] data)
	{
		_p = cast(ubyte *)data.ptr;
		_end = _p + data.length;
	}

	bool read(ubyte[] v)
	{
		if(length < v.length)
		{
			return false;
		}

		v[] = _p[0..v.length];
		_p += v.length;

		return true;
	}

	bool read(ref ubyte[] v, uint len)
	{
		if(length < len)
		{
			return false;
		}

		v = _p[0..len].dup;
		_p += len;

		return true;
	}

	bool readstr(ref string v)
	{
		auto t = _p;
		auto r = length;

		for(; r && *t; r--, t++) {}

		if(!r)
		{
			return false;
		}

		v = cast(string)_p[0..t - _p].idup;
		_p = t + 1;

		return true;
	}

	bool write(in ubyte[] v)
	{
		if(length < v.length)
		{
			return false;
		}

		_p[0..v.length] = v;
		_p += v.length;

		return true;
	}

	bool rskip(size_t cnt)
	{
		if(length < cnt)
		{
			return false;
		}

		_p += cnt;
		return true;
	}

	bool wskip(size_t cnt)
	{
		if(length < cnt)
		{
			return false;
		}

		_p += cnt;
		return true;
	}

	const data()
	{
		return _p[0..length];
	}

	const length()
	{
		return cast(size_t)(_end - _p);
	}

private:
	ubyte*
			_p,
			_end;
}

struct AppendWriter
{
	bool write(in ubyte[] v)
	{
		_data ~= v;
		return true;
	}

	bool wskip(size_t cnt)
	{
		_data.length += cnt;
		return true;
	}

	const length()
	{
		return _data.length;
	}

private:
	mixin publicProperty!(ubyte[], `data`);
}
