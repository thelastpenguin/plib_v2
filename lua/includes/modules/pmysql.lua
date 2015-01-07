pmysql = pmysql or { }
require('mysqloo')
local tostring, string, unpack, type
do
  local _obj_0 = _G
  tostring, string, unpack, type = _obj_0.tostring, _obj_0.string, _obj_0.unpack, _obj_0.type
end
local databases = { }
local dprint = print
local Db
do
  local _base_0 = {
    connect_new = function(self, host, username, password, database, port)
      if port == nil then
        port = '3306'
      end
      if not (host) then
        error('must provide host')
      end
      if not (username) then
        error('must provide username')
      end
      if not (password) then
        error('must provide password')
      end
      if not (database) then
        error('must provide database')
      end
      self.host = host
      self.username = username
      self.datbase = database
      self.port = port
      self.hash = string.format('%s:%s@%X:%s', host, port, util.CRC(username .. '-' .. password), database)
      if databases[self.hash] then
        self.db = databases[self.hash]
        return dprint('recycled database connection with hashid: ' .. self.hash)
      else
        self.db = mysqloo.connect(host, username, password, database, port)
        databases[self.hash] = self.db
        self.db.onConnected = function(self)
          return MsgC(Color(0, 255, 0), 'pMySQL connected successfully.\n')
        end
        self.db.onConnectionFailed = function(self, err)
          MsgC(Color(255, 0, 0), 'pMySQL connection failed\n')
          return error(err)
        end
        dprint('started new db connection with hash: ' .. self.hash)
        return self:connect()
      end
    end,
    connect_resume = function(self, db)
      self.hash = db.hash
      self.host = db.host
      self.username = db.username
      self.database = db.database
      self.port = db.port
      self.db = db.db
    end,
    connect = function(self)
      MsgC(Color(0, 255, 0), 'pMySQL connecting to database\n')
      local start = SysTime()
      self.db:connect()
      self.db:wait()
      return MsgC(Color(155, 155, 155), 'pMySQL connect operation complete. took: ' .. (SysTime() - start) .. ' seconds\n')
    end,
    query = function(self, sqlstr, callback)
      local query = self.db:query(sqlstr)
      query.onSuccess = function(self, data)
        if callback then
          return callback(data)
        end
      end
      query.onError = function(_, err)
        if self.db:status() == mysqloo.DATABASE_NOT_CONNECTED then
          self:connect()
        end
        dprint('QUERY FAILED!')
        dprint('SQL: ' .. sqlstr)
        dprint('ERR: ' .. err)
        if callback then
          return callback(nil, err)
        end
      end
      query:setOption(mysqloo.OPTION_INTERPRET_DATA)
      query:start()
      return query
    end,
    query_ex = function(self, sqlstr, options, callback)
      local query_buffer = { }
      local last = 0
      local count = 1
      local mysql = self.db
      while true do
        local next = sqlstr:find('?', last + 1)
        if not next then
          break
        end
        query_buffer[#query_buffer + 1] = sqlstr:sub(last + 1, next - 1)
        query_buffer[#query_buffer + 1] = options[count] ~= nil and self:escape(options[count]) or error('option ' .. count .. ' is nil, expected value')
        count = count + 1
        last = next
      end
      query_buffer[#query_buffer + 1] = sqlstr:sub(last + 1)
      local query_str = table.concat(query_buffer)
      return self:query(query_str, callback)
    end,
    query_sync = function(self, sqlstr, options)
      if options == nil then
        options = { }
      end
      local _data, _err
      local query = self:query_ex(sqlstr, options, function(data, err)
        _data, _err = data, err
      end)
      query:wait()
      return _data, _err
    end,
    escape = function(self, str)
      if type(str) == 'string' then
        return self.db:escape(str)
      else
        return self.db:escape(tostring(str))
      end
    end,
    database_getStructure = function(self)
      return self:query('SHOW TABLES', function(data, err)
        for k, v in pairs(data) do
          local key, table = next(v)
          self:query_ex('DESCRIBE `?` ', {
            table
          }, function(data, err)
            print('table info: ' .. table)
            return PrintTable(data)
          end)
        end
      end)
    end
  }
  _base_0.__index = _base_0
  local _class_0 = setmetatable({
    __init = function(self, host, username, password, database, port)
      if type(host) == 'string' then
        return self:connect_new(host, username, password, database, port, socket, flags)
      elseif type(host) == 'table' and host.db and tostring(host.db):find('Database') then
        return self:connect_resume(host)
      else
        return error('could not initialize database object')
      end
    end,
    __base = _base_0,
    __name = "Db"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Db = _class_0
end
pmysql.newdb = function(...)
  return Db(...)
end
pmysql.Db = Db
