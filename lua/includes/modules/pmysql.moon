export pmysql
pmysql or= {}

require 'mysqloo'

import tostring, string, unpack, type from _G

databases = {}

dprint = print

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
				MsgC(Color(0,255,0), 'pMySQL connected successfully.\n')
			@db.onConnectionFailed = (err) =>
				MsgC(Color(255,0,0), 'pMySQL connection failed\n')
				error(err)
			
			dprint('started new db connection with hash: '..@hash)

			@connect!
	nullify: (err) =>
		@query = =>
			error 'database connection failed. err: '..err

	connect_resume: (db) =>
		@hash = db.hash
		@host = db.host
		@username = db.username
		@database = db.database
		@port = db.port
		@db = db.db

	connect: =>
		MsgC(Color(0,255,0), 'pMySQL connecting to database\n')
		start = SysTime!
		@db\connect!
		@db\wait!
		MsgC(Color(155,155,155), 'pMySQL connect operation complete. took: '..(SysTime! - start)..' seconds\n')

	query: (sqlstr, callback) =>
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
		
	query_ex: (sqlstr, options, callback) =>
		query_buffer = {}
		last = 0
		count = 1
		mysql = @db -- bit of a performance boost
		
		while true 
			next = sqlstr\find('?', last+1)
			break if not next

			query_buffer[#query_buffer+1] = sqlstr\sub(last+1, next-1)
			query_buffer[#query_buffer+1] = options[count] ~= nil and @escape(options[count]) or error('option '..count..' is nil, expected value')
			count += 1

			last = next

		query_buffer[#query_buffer+1] = sqlstr\sub(last+1)
		query_str = table.concat(query_buffer)
		return @query(query_str, callback)

	query_sync: (sqlstr, options = {}) =>
		local _data, _err
		query = @query_ex sqlstr, options, (data, err) ->
			_data, _err = data, err
		query\wait()
		return _data, _err

	escape: (str) =>
		if type(str) == 'string'
			return @db\escape(str)
		else
			return @db\escape(tostring(str))

	database_getStructure: () =>
		@query 'SHOW TABLES', (data, err) ->
			for k,v in pairs(data)
				key, table = next(v)
				
				@query_ex 'DESCRIBE `?` ', {table}, (data, err) ->
					print('table info: '..table)
					PrintTable(data)
	
pmysql.newdb = (...) ->
	Db(...)
	
pmysql.Db = Db