module utils.logger;


import
		std.stdio,
		std.range,
		std.string,

		arsd.terminal;


struct Logger
{
	void info(A...)(A args)
	{
		log(Color.green | Bright, args);
	}

	void info2(A...)(A args)
	{
		log(Color.magenta | Bright, args);
	}

	void info3(A...)(A args)
	{
		log(Color.white, args);
	}

	void error(A...)(A args)
	{
		log(Color.red | Bright, args);
	}

	void warning(A...)(A args)
	{
		log(Color.yellow | Bright, args);
	}

	void opCall(A...)(A args)
	{
		log(Color.cyan | Bright, args);
	}

	ubyte ident;
private:
	void log(A...)(int c, A args)
	{
		static if(args.length == 1)
		{
			auto term = Terminal(ConsoleOutputType.minimalProcessing);
			term.color(c, Color.DEFAULT);

			"\t".repeat(ident).join.write;
			args[0].writeln;
		}
		else
		{
			log(c, format(args));
		}
	}
}

__gshared Logger logger;
