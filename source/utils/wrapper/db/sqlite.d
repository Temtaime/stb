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

		etc.c.sqlite3,
		utils.wrapper.except;


final class SQLite
{
	this(string name)
	{
		sqlite3_open(name.toStringz, &_db) == SQLITE_OK || throwError(lastError);
	}

	~this()
	{
		_stmts.byValue.each!(a => remove(a));
		sqlite3_close(_db);
	}

	void backup(SQLite dest)
	{
		auto bk = sqlite3_backup_init(dest._db, `main`, _db, `main`);
		bk || throwError(dest.lastError);

		scope(exit)
		{
			sqlite3_backup_finish(bk);
		}

		auto rc = sqlite3_backup_step(bk, -1);
		rc == SQLITE_DONE || throwError(`error backuping db: %s`, rc);
	}

package:
	void process(sqlite3_stmt* stmt)
	{
		execute(stmt);
		sqlite3_reset(stmt);
	}

	auto process(A...)(sqlite3_stmt* stmt)
	{
		auto self = this; // TODO: DMD BUG

		struct S
		{
			this(this) @disable;

			~this()
			{
				sqlite3_reset(stmt);
			}

			const empty()
			{
				return !_hasRow;
			}

			void popFront()
			{
				assert(!empty);
				_hasRow = self.execute(stmt);
			}

			auto array()
			{
				ReturnType!front[] res;

				for(; _hasRow; popFront)
				{
					res ~= front;
				}

				return res;
			}

			auto front()
			{
				assert(_hasRow);

				Tuple!A r;

				foreach(i, ref v; r)
				{
					alias T = A[i];

					v = sqlite3_column_text(stmt, i).fromStringz.to!T;

					static if(isSomeString!T)
					{
						v = v.idup;
					}
				}

				static if(A.length > 1)
				{
					return r;
				}
				else
				{
					return r[0];
				}
			}

		private:
			bool _hasRow;
		}

		return S(execute(stmt));
	}

	auto prepare(string sql)
	{
		auto stmt = _stmts.get(sql, null);

		if(!stmt)
		{
			sqlite3_prepare_v2(_db, sql.toStringz, cast(int)sql.length, &stmt, null) == SQLITE_OK || throwError(lastError);
			_stmts[sql] = stmt;
		}

		return stmt;
	}

	void bind(A...)(sqlite3_stmt* stmt, A args)
	{
		foreach(uint i, v; args)
		{
			int res;

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

			res == SQLITE_OK || throwError(lastError);
		}
	}

	auto lastId(sqlite3_stmt*)
	{
		return sqlite3_last_insert_rowid(_db);
	}

	auto affected(sqlite3_stmt*)
	{
		return sqlite3_changes(_db);
	}

private:
	void remove(sqlite3_stmt* stmt)
	{
		sqlite3_finalize(stmt);
	}

	bool execute(sqlite3_stmt* stmt)
	{
		auto res = sqlite3_step(stmt);
		res == SQLITE_ROW || res == SQLITE_DONE || throwError(lastError);
		return res == SQLITE_ROW;
	}

	auto lastError()
	{
		return sqlite3_errmsg(_db).fromStringz;
	}

	sqlite3* _db;
	sqlite3_stmt*[string] _stmts;
}
