module stb;
public import stb_main;

int binarySearch(int min, int max, int delegate(int) comp, bool lower = true)
{
	stb_search s;
	auto res = stb_search_binary(&s, min, max, lower);

	while (stb_probe(&s, comp(res), &res))
	{
	}

	return res;
}

static this()
{
    // To prevent linker from stripping the symbol
    auto f = &compress_for_stb_image_write;
}
