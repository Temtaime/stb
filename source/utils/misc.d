module utils.misc;

import
		std.traits;


mixin template publicProperty(T, string name, string value = null)
{
	mixin(`
		public ref ` ~ name ~ `() @property const { return _` ~ name ~ `; }
		T _` ~ name ~ (value.length ? `=` ~ value : null) ~ `;`
																);
}

auto as(T, E)(E data) if(isDynamicArray!E)
{
	return cast(T[])data;
}

auto as(T, E)(ref E data) if(!isDynamicArray!E)
{
	return cast(T[])(&data)[0..1];
}

auto toByte(T)(auto ref T data)
{
	return data.as!ubyte;
}
