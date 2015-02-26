export ezsqloo
ezsqloo or= {}

require 'mysqloo'
require 'dprint'
require 'xfn'

mysqloo = mysqloo
import tostring, string, unpack, type from _G
import pairs, ipairs, table from _G

--
-- UTILITIES
--
local formatValue, formatTableElement, escapeColumn

formatters = {}
formatValue = (val,db,noParens) ->
	formatters[type(val)](val, db, noParens)

formatters['number'] = (val,db) ->
	tostring(val)
formatters['string'] = (val,db) ->
	'\''..db\escape(val)..'\''
formatters['table'] = (val,db,noParens) ->
	if val[1] ~= nil
		vals = [formatValue(v,db) for v in *val]
		if noParens
			table.concat(vals, ',')
		else
			'('..table.concat(vals, ',')..')'
	else
		vals = ['`'..k..'`='..formatValue(v,db) for k,v in pairs(val)]
		table.concat vals, ','

formatTableElement = (db, k, v) ->
	t = type(k)
	if t == 'number'
		tv = type(v)
		if tv == 'table'
			'('..formatValue(db, v)..')'
		else
			formatValue(db, v)
	elseif t == 'string'
		-- eventually the column name 'k' should be escaped
		'`'.. k .. '`=' .. formatValue(db, v)

formatArguments = (db, args) ->
	for k,v in ipairs(args)
		args[k] = formatValue(v,db,true)

databases = {}

class Db
	new: ( host, username, password, database, port ) =>
		if type(host) == 'string'
			@connect_new(host, username, password, database, port, socket, flags)
		elseif type(host) == 'table' and host.db and tostring(host.db)\find('Database')
			@connect_resume(host)
		else
			error 'could not initialize database object'

	connect_new: (host, username, password, database, port = '3306') =>
		error('must provide host') unless host
		error('must provide username') unless username
		error('must provide password') unless password
		error('must provide database') unless database

		@host = host
		@username = username
		@datbase = database
		@port = port

		@hash = string.format('%s:%s@%X:%s', host, port, util.CRC(username..'-'..password), database)
		if databases[@hash]
			@db = databases[@hash]
			dprint('recycled database connection with hashid: '..@hash)
		else
			@db = mysqloo.connect( host, username, password, database, port )
			databases[@hash] = @db -- cache the connection so other instances can recycle it
			
			-- events on connection
			@db.onConnected = () => 
				MsgC(Color(0,255,0), 'ezSQLoo connected successfully.\n')
			@db.onConnectionFailed = (err) =>
				MsgC(Color(255,0,0), 'ezSQLoo connection failed\n')
				error(err)
			
			dprint('started new db connection with hash: '..@hash)

			@connect!

	connect_resume: (db) =>
		@hash = db.hash
		@host = db.host
		@username = db.username
		@database = db.database
		@port = db.port
		@db = db.db

	connect: =>
		MsgC(Color(0,255,0), 'ezSQLoo connecting to database\n')
		start = SysTime!
		@db\connect!
		@db\wait!
		MsgC(Color(155,155,155), 'ezSQLoo connect operation complete. took: '..(SysTime! - start)..' seconds\n')

	escape: (str) =>
		return @db\escape(str)

	_query: (sqlstr, callback) =>
		query = @db\query(sqlstr)
		query.onSuccess = (data) =>
			callback(data) if callback
		query.onError = (_, err) ->
			if @db\status! == mysqloo.DATABASE_NOT_CONNECTED
				@connect!

			dprint('QUERY FAILED!')
			dprint('SQL: '..sqlstr)
			dprint('ERR: '..err)
			
			callback(nil, err) if callback

		query\setOption( mysqloo.OPTION_INTERPRET_DATA )
		query\start!
		return query

	query: (sqlstr, ...) =>
		args = {...}
		local cback
		if type(args[#args]) == 'function'
			cback = table.remove(args, #args)
		else
			cback = xfn.noop

		-- transform query arguments as desired
		formatArguments(self, args)

		count = 0
		sqlstr = sqlstr\gsub '?', (match) ->
			count += 1
			return args[count]

		return @_query(sqlstr, cback)

	query_sync: (sqlstr, ...) =>
		args = {...}
		formatArguments(self, args)

		count = 0
		sqlstr = sqlstr\gsub '?', (match) ->
			count += 1
			return args[count]

		local _data, _err
		query = @_query sqlstr, (data, err) ->
			_data = data
			_err = err

		query\wait!

		return _data, _err

ezsqloo.newdb = (...) ->
	Db(...)
	
ezsqloo.Db = Db