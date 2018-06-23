module utils.except;

import
		std.conv,
		std.format,
		std.exception;


bool throwError(string S, string F = __FILE__, size_t L = __LINE__, A...)(A args) if(__traits(compiles, format!S(args)))
{
	return throwError(format!S(args), F, L);
}

bool throwError(string S, A...)(string f, size_t l, A args) if(__traits(compiles, format!S(args)))
{
	return throwError(format!S(args), f, l);
}

bool throwError(T)(T t, string f = __FILE__, size_t l = __LINE__)
{
	throw new Exception(t.to!string, f, l);
}
