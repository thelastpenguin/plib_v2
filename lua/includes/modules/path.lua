path = path or { }
require('pstructs')
local getinfo
do
  local _obj_0 = debug
  getinfo = _obj_0.getinfo
end
local Stack
do
  local _obj_0 = pstruct
  Stack = _obj_0.Stack
end
local Read, Write, Open, Exists, IsDir, MakeDir
do
  local _obj_0 = file
  Read, Write, Open, Exists, IsDir, MakeDir = _obj_0.Read, _obj_0.Write, _obj_0.Open, _obj_0.Exists, _obj_0.IsDir, _obj_0.MakeDir
end
local find, sub, match, len
do
  local _obj_0 = string
  find, sub, match, len = _obj_0.find, _obj_0.sub, _obj_0.match, _obj_0.len
end
local concat
do
  local _obj_0 = table
  concat = _obj_0.concat
end
local select = select
path.curfile = function()
  return getinfo(2, 'S').short_src
end
path.cwd = function()
  return match(getinfo(2, 'S').short_src, '(.*)/.*%.[^.]*')
end
path.parts = function(path)
  return match(path, '(.*)/(.*)%.([^.]*)')
end
local file
file = function(path)
  return match(path, '.*/(.*)%.[^.]*')
end
path.file = file
local directory
directory = function(path)
  return match(path, '(.*)/.*%.[^.]*')
end
local _ = path.directory
local extension
extension = function(path)
  return match(path, '.*/.*%.([^.]*)')
end
_ = path.extension
path.condense = function(...)
  local stack = Stack()
  local numparts = select('#', ...)
  local curpart = 1
  path = select(curpart, ...)
  local last = 0
  while true do
    local next = find(path, '/', last + 1)
    local seg = sub(path, last + 1, next and next - 1)
    if len(seg) > 0 then
      if seg == '..' then
        stack:pop()
      elseif seg ~= '.' then
        stack:push(seg)
      end
    end
    if next then
      last = next
    elseif curpart < numparts then
      curpart = curpart + 1
      path = select(curpart, ...)
      last = 0
    else
      break
    end
  end
  return concat(stack:getValues(), '/')
end
path.join = function(...)
  return path.condense(concat({
    ...
  }))
end
path.rebase = function(path, root)
  local rootIndex
  _, rootIndex = find(path, root, 1, true)
  if rootIndex then
    return sub(path, rootIndex + 2)
  else
    return path
  end
end
