ezsqloo = ezsqloo or { }
require('mysqloo')
require('dprint')
require('xfn')
local mysqloo = mysqloo
local tostring, string, unpack, type
do
  local _obj_0 = _G
  tostring, string, unpack, type = _obj_0.tostring, _obj_0.string, _obj_0.unpack, _obj_0.type
end
local pairs, ipairs, table
do
  local _obj_0 = _G
  pairs, ipairs, table = _obj_0.pairs, _obj_0.ipairs, _obj_0.table
end
local formatValue, formatTableElement, escapeColumn
local formatters = { }
formatValue = function(val, db, noParens)
  return formatters[type(val)](val, db, noParens)
end
formatters['number'] = function(val, db)
  return tostring(val)
end
formatters['string'] = function(val, db)
  return '\'' .. db:escape(val) .. '\''
end
formatters['table'] = function(val, db, noParens)
  if val[1] ~= nil then
    local vals
    do
      local _accum_0 = { }
      local _len_0 = 1
      for _index_0 = 1, #val do
        local v = val[_index_0]
        _accum_0[_len_0] = formatValue(v, db)
        _len_0 = _len_0 + 1
      end
      vals = _accum_0
    end
    if noParens then
      return table.concat(vals, ',')
    else
      return '(' .. table.concat(vals, ',') .. ')'
    end
  else
    local vals
    do
      local _accum_0 = { }
      local _len_0 = 1
      for k, v in pairs(val) do
        _accum_0[_len_0] = '`' .. k .. '`=' .. formatValue(v, db)
        _len_0 = _len_0 + 1
      end
      vals = _accum_0
    end
    return table.concat(vals, ',')
  end
end
formatTableElement = function(db, k, v)
  local t = type(k)
  if t == 'number' then
    local tv = type(v)
    if tv == 'table' then
      return '(' .. formatValue(db, v) .. ')'
    else
      return formatValue(db, v)
    end
  elseif t == 'string' then
    return '`' .. k .. '`=' .. formatValue(db, v)
  end
end
local formatArguments
formatArguments = function(db, args)
  for k, v in ipairs(args) do
    args[k] = formatValue(v, db, true)
  end
end
local databases = { }
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
          return MsgC(Color(0, 255, 0), 'ezSQLoo connected successfully.\n')
        end
        self.db.onConnectionFailed = function(self, err)
          MsgC(Color(255, 0, 0), 'ezSQLoo connection failed\n')
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
      MsgC(Color(0, 255, 0), 'ezSQLoo connecting to database\n')
      local start = SysTime()
      self.db:connect()
      self.db:wait()
      return MsgC(Color(155, 155, 155), 'ezSQLoo connect operation complete. took: ' .. (SysTime() - start) .. ' seconds\n')
    end,
    escape = function(self, str)
      return self.db:escape(str)
    end,
    _query = function(self, sqlstr, callback)
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
    query = function(self, sqlstr, ...)
      local args = {
        ...
      }
      local cback
      if type(args[#args]) == 'function' then
        cback = table.remove(args, #args)
      else
        cback = xfn.noop
      end
      formatArguments(self, args)
      local count = 0
      sqlstr = sqlstr:gsub('?', function(match)
        count = count + 1
        return args[count]
      end)
      return self:_query(sqlstr, cback)
    end,
    query_sync = function(self, sqlstr, ...)
      local args = {
        ...
      }
      formatArguments(self, args)
      local count = 0
      sqlstr = sqlstr:gsub('?', function(match)
        count = count + 1
        return args[count]
      end)
      local _data, _err
      local query = self:_query(sqlstr, function(data, err)
        _data = data
        _err = err
      end)
      query:wait()
      return _data, _err
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
ezsqloo.newdb = function(...)
  return Db(...)
end
ezsqloo.Db = Db
