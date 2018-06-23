module utils.binary.helpers;

import
		std.meta,
		std.array,
		std.range,
		std.traits;


auto checkAttrs(string[] arr...)
{
	while(arr.length)
	{
		switch(arr.front)
		{
		case `default`, `skip`, `length`, `ignoreif`, `validif`:
			arr.popFront;
			goto case;

		case `rest`, `ubyte`, `ushort`, `uint`:
			arr.popFront;
			break;

		default:
			return arr.front;
		}
	}

	return null;
}

template isDataSimple(T)
{
	static if(isBasicType!T)
	{
		enum isDataSimple = true;
	}
	else static if(isStaticArray!T)
	{
		enum isDataSimple = isDataSimple!(ElementEncodingType!T);
	}
	else
	{
		enum isDataSimple = false;
	}
}

auto StructExecuter(alias _expr, D, S, P, R)(ref D CUR, ref S STRUCT, ref P PARENT, ref R READER)
{
	with(CUR)
	{
		return mixin(_expr);
	}
}

@property fieldsToProcess(T)()
{
	int k, sz;

	string u;
	string[] res;

	void add()
	{
		if(u.length)
		{
			res ~= u;
			u = null;
		}
	}

	foreach(name; __traits(allMembers, T))
	{
		static if(__traits(getProtection, __traits(getMember, T, name)) == `public`)
		{
			alias E = Alias!(__traits(getMember, T, name));

			static if(!(is(FunctionTypeOf!E == function) || hasUDA!(E, `ignore`)))
			{
				static if(is(typeof(E.offsetof)) && isAssignable!(typeof(E)))
				{
					uint x = E.offsetof, s = E.sizeof;

					if(k != x)
					{
						add;
						u = name;

						k = x;
						sz = s;
					}
					else if(s > sz)
					{
						u = name;
						sz = s;
					}
				}
				else static if(__traits(compiles, &E) && is(typeof(E) == immutable))
				{
					add;
					res ~= name;
				}
			}
		}
	}

	add;
	return res;
}
