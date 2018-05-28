module utils.wrapper.db;

import
		std.typecons;

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
