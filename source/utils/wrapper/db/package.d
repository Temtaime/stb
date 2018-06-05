module utils.wrapper.db;

import
		std.typecons,

		utils.wrapper.except;

public import
				utils.wrapper.db.mysql,
				utils.wrapper.db.sqlite;


template query(T...)
{
	auto query(R, A...)(R db, string sql, A args) if(is(R == SQLite) || is(R == MySQL))
	{
		auto stmt = db.prepare(sql);
		db.bind(stmt, args);

		static if(T.length)
		{
			return db.process!T(stmt);
		}
		else
		{
			db.process(stmt);
			return tuple!(`affected`, `lastId`)(db.affected(stmt), db.lastId(stmt));
		}
	}
}

template queryOne(T...)
{
	auto queryOne(R, A...)(R db, string sql, A args) if(is(R == SQLite) || is(R == MySQL))
	{
		auto res = db.query!T(sql, args);
		res.empty && throwError(`query returned no rows`);

		auto e = res.front;
		res.popFront;

		res.empty || throwError(`query returned multiple rows`);
		return e;
	}
}

unittest
{
	auto db = new SQLite(`:memory:`);

	auto res = db.query!(uint, string)(`select ?, ?;`, 123, `hello`);
	auto res2 = db.queryOne!(uint, string)(`select ?, ?;`, 123, `hello`);
}
