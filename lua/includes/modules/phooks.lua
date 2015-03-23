
if SERVER then
	AddCSLuaFile()
end

local oldHooks 		= hook.GetTable()

hook 				= {}

local hook 			= hook
local table_remove 	= table.remove
local table_copy 	= table.Copy
local debug_info 	= debug.getinfo
local type 			= type
local ipairs 		= ipairs
local IsValid 		= IsValid

local hooks 		= {}
local mappings 		= {}

hook.GetTable = function()
	return table_copy(mappings)
end

hook.Call = function(name, gm, ...) 
	local collection = hooks[name]
	
	local a, b, c, d, e
	if collection ~= nil then
		for k,v in ipairs(collection) do
			a, b, c, d, e = v(...)
			if a ~= nil then
				return a, b, c, d, e
			end
		end
	end

	if gm ~= nil then
		local gmfunc = gm[name]
		if gmfunc then
			return gmfunc(gm, ...)
		end
	end
end

local hook_Call = hook.Call
hook.Run = function(name, ...)
	hook_Call(name, GAMEMODE, ...)
end

hook.Remove = function(name, id)
	local collection = hooks[name]
	if collection ~= nil then
		local func = mappings[name][id]
		if func ~= nil then
			for k,v in ipairs(collection) do
				if func == v then
					table_remove(collection, k)
					break 
				end
			end
		end
		mappings[name][id] = nil
	end
end

local hook_Remove = hook.Remove
hook.Add = function(name, id, func) 

	if type(id) == 'function' then
		func = id
		id = debug_info(func).short_src
	end
	hook_Remove(name, id) -- properly simulate hook overwrite behavior

	if type(id) ~= 'string' then
		local orig = func
		func = function(...)
			if IsValid(id) then
				return orig(id, ...)
			else
				hook_Remove(name, id)
			end
		end
	end

	local collection = hooks[name]
	
	if collection == nil then
		collection = {}
		hooks[name] = collection
		mappings[name] = {}
	end

	local mapping = mappings[name]

	collection[#collection+1] = func
	mapping[id] = func
end


for name, collection in pairs(oldHooks) do
	for id, func in pairs(collection) do
		hook.Add(name, id, func)
	end
end