module stb.image.color;
import std, core.bitop;

struct Color
{
	this(uint r, uint g, uint b, uint a = 0)
	{
		this.r = cast(ubyte)r;
		this.g = cast(ubyte)g;
		this.b = cast(ubyte)b;
		this.a = cast(ubyte)a;
	}

	static fromInt(uint n)
	{
		n = n.bswap;
		return *cast(Color*)&n;
	}

	const
	{
		auto opBinary(string op : `*`)(in Color c)
		{
			return Color(
				r * c.r / 255,
				g * c.g / 255,
				b * c.b / 255,
				a * c.a / 255
			);
		}

		auto opBinary(string op : `+`)(in Color c)
		{
			return Color(
				min(r + c.r, 255),
				min(g + c.g, 255),
				min(b + c.b, 255),
				min(a + c.a, 255)
			);
		}

		auto opBinary(string op : `^`)(in Color c)
		{
			// TODO: CHECK FOR CORRECTNESS
			auto od = 255 - c.a;
			auto ra = c.a + a * od / 255;

			// TODO: WORKAROUND
			if (!ra)
			{
				ra = 1;
			}

			return Color(
				(c.r * c.a + r * a * od / 255) / ra,
				(c.g * c.a + g * a * od / 255) / ra,
				(c.b * c.a + b * a * od / 255) / ra,
				ra
			);
		}

		bool isGray(ubyte n)
		{
			auto a = min(r, g, b), b = max(r, g, b);
			return abs(a - b) < 30 && b < n;
		}

		bool compare(in Color c, ubyte d)
		{
			return abs(r - c.r) + abs(g - c.g) + abs(b - c.b) + abs(a - c.a) <= d * 4;
		}
	}

	ref opOpAssign(string op)(in Color c)
	{
		return this = this.opBinary!op(c);
	}

	ubyte r,
	g,
	b,
	a;
}

static assert(Color.sizeof == 4);

enum
{
	colorGray = Color(128, 128, 128, 200),
	colorBlack = Color(0, 0, 0, 255),
	colorWhite = Color(255, 255, 255, 255),
	colorTransparent = Color.init,
}
