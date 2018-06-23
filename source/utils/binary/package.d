module utils.binary;

import
		std.conv,
		std.range,
		std.traits,
		std.typecons,
		std.algorithm,
		std.typetuple,

		utils.misc,
		utils.except,
		utils.binary.helpers;

public import
				utils.binary.funcs,
				utils.binary.readers;


struct BinaryReader(Reader)
{
	this(A...)(auto ref A args)
	{
		reader = Reader(args);
	}

	auto read(T)(string f = __FILE__, uint l = __LINE__) if(is(T == struct))
	{
		_l = l;
		_f = f;
		_info = T.stringof;

		T t;
		process(t, t, t);
		return t;
	}

	ref write(T)(auto ref in T t, string f = __FILE__, uint l = __LINE__) if(is(T == struct))
	{
		_l = l;
		_f = f;
		_info = T.stringof;

		process!true(t, t, t);
		return this;
	}

	Reader reader;
private:
	debug
	{
		enum errorRead = `throwError!"can't read %s.%s variable"(_f, _l, _info, name)`;
		enum errorWrite = `throwError!"can't write %s.%s variable"(_f, _l, _info, name)`;
		enum errorRSkip = `throwError!"can't skip when reading %s.%s variable"(_f, _l, _info, name)`;
		enum errorWSkip = `throwError!"can't skip when writing %s.%s variable"(_f, _l, _info, name)`;
		enum errorCheck = `throwError!"variable %s.%s mismatch(%s when %s expected)"(_f, _l, _info, name, tmp, *p)`;
		enum errorValid = `throwError!"variable %s.%s has invalid value %s"(_f, _l, _info, name, *p)`;
	}
	else
	{
		enum errorRead = `throwError!"can't read %s"(_f, _l, _info)`;
		enum errorWrite = `throwError!"can't write %s"(_f, _l, _info)`;
		enum errorRSkip = errorRead;
		enum errorWSkip = errorWrite;
		enum errorCheck = errorRead;
		enum errorValid = errorRead;
	}

	enum checkLength = `E.sizeof * elemsCnt < 512 * 1024 * 1024 || throwError!"length of %s.%s variable is too big(%u)"(_f, _l, _info, name, elemsCnt);`;

	void process(bool isWrite = false, T, S, P)(ref T data, ref S st, ref P parent)
	{
		foreach(name; aliasSeqOf!(fieldsToProcess!T()))
		{
			enum Elem = T.stringof ~ `.` ~ name;

			alias attrs = TypeTuple!(__traits(getAttributes, __traits(getMember, T, name)));

			debug
			{
				enum att = checkAttrs(attrs);

				static assert(!att.length, Elem ~ ` has invalid attribute ` ~ att);
			}

			auto p = &__traits(getMember, data, name);
			alias R = typeof(*p);

			{
				enum idx = staticIndexOf!(`skip`, attrs);

				static if(idx >= 0)
				{
					size_t cnt = StructExecuter!(attrs[idx + 1])(data, st, parent, reader);

					static if(isWrite)
					{
						reader.wskip(cnt) || mixin(errorWSkip);
					}
					else
					{
						reader.rskip(cnt) || mixin(errorRSkip);
					}
				}
			}

			{
				enum idx = staticIndexOf!(`ignoreif`, attrs);

				static if(idx >= 0)
				{
					auto v = StructExecuter!(attrs[idx + 1])(data, st, parent, reader);

					if(v)
					{
						static if(!isWrite)
						{
							enum def = staticIndexOf!(`default`, attrs);

							static if(def >= 0)
							{
								*p = StructExecuter!(attrs[def + 1])(data, st, parent, reader);
							}
						}

						continue;
					}
				}
			}

			static if(!isWrite)
			{
				static if(is(R == immutable))
				{
					Unqual!R tmp;
					auto varPtr = &tmp;
				}
				else
				{
					alias varPtr = p;
				}
			}

			static if(isDataSimple!R)
			{
				static if(isWrite)
				{
					reader.write(toByte(*p)) || mixin(errorWrite);
				}
				else
				{
					reader.read(toByte(*varPtr)) || mixin(errorRead);
				}
			}
			else static if(isAssociativeArray!R)
			{
				struct Pair
				{
					Unqual!(KeyType!R) key;
					Unqual!(ValueType!R) value;
				}

				struct AA
				{
					mixin(`@(` ~ [ attrs ].to!string[1..$ - 1] ~ `) Pair[] ` ~ name ~ `;`);
				}

				AA aa;
				auto arr = &aa.tupleof[0];

				static if(isWrite)
				{
					*arr = p.byKeyValue.map!(a => Pair(a.key, a.value)).array;
				}

				process!isWrite(aa, st, data);

				static if(!isWrite)
				{
					*p = map!(a => tuple(a.tupleof))(*arr).assocArray;
				}
			}
			else static if(isArray!R)
			{
				alias E = ElementEncodingType!R;

				enum isElemSimple = isDataSimple!E;
				enum lenIdx = staticIndexOf!(`length`, attrs);

				static assert(isElemSimple || is(E == struct), `can't serialize ` ~ Elem);

				static if(lenIdx >= 0)
				{
					uint elemsCnt = StructExecuter!(attrs[lenIdx + 1])(data, st, parent, reader);

					static if(isWrite)
					{
						assert(p.length == elemsCnt);
					}

					enum isRest = false;
				}
				else
				{
					static if(staticIndexOf!(`ubyte`, attrs) >= 0)			alias L = ubyte;
					else static if(staticIndexOf!(`ushort`, attrs) >= 0)	alias L = ushort;
					else static if(staticIndexOf!(`uint`, attrs) >= 0)		alias L = uint;
					else static if(staticIndexOf!(`ulong`, attrs) >= 0)		alias L = ulong;

					static if(is(L))
					{
						L elemsCnt;

						static if(isWrite)
						{
							assert(p.length <= L.max);

							elemsCnt = cast(L)p.length;
							reader.write(elemsCnt.toByte) || mixin(errorWrite);
						}
						else
						{
							reader.read(elemsCnt.toByte) || mixin(errorRead);
						}

						enum isRest = false;
					}
					else
					{
						enum isRest = staticIndexOf!(`rest`, attrs) >= 0;
					}
				}

				enum isStr = is(R : string);
				enum isLen = is(typeof(elemsCnt));
				enum isDyn = isDynamicArray!R;

				static if(isDyn)
				{
					static assert(isStr || isLen || isRest, `length of ` ~ Elem ~ ` is unknown`);
				}
				else
				{
					static assert(!(isLen || isRest), `static array ` ~ Elem ~ ` can't have a length`);
				}

				static if(isElemSimple)
				{
					static if(isWrite)
					{
						reader.write(toByte(*p)) || mixin(errorWrite);

						static if(isStr && !isLen)
						{
							reader.wskip(1) || mixin(errorWSkip);
						}
					}
					else
					{
						static if(isStr && !isLen)
						{
							reader.readstr(*varPtr) || mixin(errorRead);
						}
						else
						{
							ubyte[] arr;

							static if(isRest)
							{
								!(reader.length % E.sizeof) && reader.read(arr, cast(uint)reader.length) || mixin(errorRead);
							}
							else
							{
								mixin(checkLength);

								reader.read(arr, elemsCnt * cast(uint)E.sizeof) || mixin(errorRead);
							}

							*varPtr = (cast(E *)arr.ptr)[0..arr.length / E.sizeof];
						}
					}
				}
				else
				{
					debug
					{
						auto old = _info;
						_info ~= `.` ~ name;
					}

					static if(isWrite)
					{
						foreach(ref v; *p)
						{
							process!isWrite(v, st, data);
						}
					}
					else
					{
						static if(isRest)
						{
							while(reader.length)
							{
								E v;
								process!isWrite(v, st, data);

								*varPtr ~= v;
							}
						}
						else
						{
							static if(isDyn)
							{
								mixin(checkLength);

								*varPtr = new E[elemsCnt];
							}

							foreach(ref v; *varPtr)
							{
								process!isWrite(v, st, data);
							}
						}
					}

					debug
					{
						_info = old;
					}
				}
			}
			else
			{
				debug
				{
					auto old = _info;
					_info ~= `.` ~ name;
				}

				process!isWrite(*p, st, data);

				debug
				{
					_info = old;
				}
			}

			static if(!isWrite)
			{
				static if(is(typeof(tmp)))
				{
					tmp == *p || mixin(errorCheck);
				}

				enum idx = staticIndexOf!(`validif`, attrs);

				static if(idx >= 0)
				{
					StructExecuter!(attrs[idx + 1])(data, st, parent, reader) || mixin(errorValid);
				}
			}
		}
	}

	uint _l;

	string
			_f,
			_info;
}
