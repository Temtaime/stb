module utils.wrapper.except;

import
		std.conv,
		std.exception;


bool throwError(string F = __FILE__, size_t L = __LINE__, A...)(A args) if(A.length)
{
	static if(A.length > 1)
	{
		return throwErrorImpl(format(args), F, L);
	}
	else
	{
		return throwErrorImpl(args[0].to!string, F, L);
	}
}

bool throwErrorImpl(string s, string file, size_t line)
{
	throw new Exception(s, file, line);
}
