module utils.wrapper.db.sqlite;

import
		std.conv,
		std.meta,
		std.array,
		std.string,
		std.traits,
		std.typecons,
		std.exception,
		std.algorithm,

		etc.c.sqlite3;


final class SQLite
{
	this(string name)
	{
		enforce(sqlite3_open(name.toStringz, &_db) == SQLITE_OK, lastError);
	}

	~this()
	{
		_stmts.byValue.each!(a => remove(a));
		sqlite3_close(_db);
	}

package:
	void process(sqlite3_stmt* stmt)
	{
		execute(stmt);
		sqlite3_reset(stmt);
	}

	auto process(T)(sqlite3_stmt* stmt)
	{
		auto that = this; // TODO: DMD BUG

		struct S
		{
			this(this) @disable;

			~this()
			{
				sqlite3_reset(stmt);
			}

			bool empty() const
			{
				return _empty;
			}

			void popFront()
			{
				assert(!empty);
				_empty = !that.execute(stmt);
			}

			auto front()
			{
				Tuple!T r;

				foreach(i, ref v; r)
				{
					v = sqlite3_column_text(stmt, i).fromStringz.to!(typeof(v));
				}

				return r;
			}

		private:
			bool _empty;
		}

		return S(!execute(stmt));
	}

	auto prepare(string sql)
	{
		auto stmt = _stmts.get(sql, null);

		if(!stmt)
		{
			enforce(sqlite3_prepare_v2(_db, sql.toStringz, cast(int)sql.length, &stmt, null) == SQLITE_OK, lastError);
			_stmts[sql] = stmt;
		}

		return stmt;
	}

	void bind(A...)(sqlite3_stmt* stmt, A args)
	{
		int res;

		foreach(uint i, v; args)
		{
			alias T = typeof(v);
			auto idx = i + 1;

			static if(is(T == typeof(null)))
			{
				res = sqlite3_bind_null(stmt, idx);
			}
			else static if(isFloatingPoint!T)
			{
				res = sqlite3_bind_double(stmt, idx, v);
			}
			else static if(isIntegral!T)
			{
				res = sqlite3_bind_int64(stmt, idx, v);
			}
			else static if(isSomeString!T)
			{
				res = sqlite3_bind_text(stmt, idx, v.toStringz, cast(int)v.length, SQLITE_TRANSIENT);
			}
			else
			{
				static assert(false);
			}
		}

		enforce(res == SQLITE_OK, lastError);
	}

	auto lastId()
	{
		return cast(uint)sqlite3_last_insert_rowid(_db);
	}

	auto affected()
	{
		return cast(uint)sqlite3_changes(_db);
	}

private:
	void remove(sqlite3_stmt* stmt)
	{
		sqlite3_finalize(stmt);
	}

	bool execute(sqlite3_stmt* stmt)
	{
		auto res = sqlite3_step(stmt);
		enforce(res == SQLITE_ROW || res == SQLITE_DONE, lastError);
		return res == SQLITE_ROW;
	}

	auto lastError()
	{
		return sqlite3_errmsg(_db).fromStringz.assumeUnique;
	}

	sqlite3* _db;
	sqlite3_stmt*[string] _stmts;
}
