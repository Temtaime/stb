module utils.logger;


import
		std.conv,
		std.range,
		std.string,
		std.algorithm,

		core.stdc.stdio,

		utils.console;


struct Logger
{
	void info(A...)(A args)
	{
		log(CC_FG_GREEN, args);
	}

	void info2(A...)(A args)
	{
		log(CC_FG_MAGENTA, args);
	}

	void info3(A...)(A args)
	{
		log(CC_FG_WHITE, args);
	}

	void error(A...)(A args)
	{
		log(CC_FG_RED, args);
	}

	void warning(A...)(A args)
	{
		log(CC_FG_YELLOW, args);
	}

	void opCall(A...)(A args)
	{
		log(CC_FG_CYAN, args);
	}

	ubyte ident;
private:
	void log(A...)(int c, A args)
	{
		static if(args.length == 1)
		{
			ident.iota.each!(a => write(c, "\t"));
			write(c, args[0].to!string);
			write(c, "\n");
		}
		else
		{
			log(c, format(args));
		}
	}

	void write(int color, string s)
	{
		cc_fprintf(color, stdout, "%.*s", s.length, s.ptr);
	}
}

__gshared Logger logger;

unittest
{
	logger(`hello, world`);
}
