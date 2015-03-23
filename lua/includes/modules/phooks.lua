
local oldHooks = hook.GetTable()

hook = {}

local hooks = {}
local mappings = {}

hook.GetTable = function()
	return table.Copy(mappings)
end

hook.Add = function(name, id, func) 
	if type(id) == 'function' then
		func = id
		id = debug.getinfo(func).short_src
	end

	if type(id) ~= 'string' then
		local orig = func
		func = function(...)
			if IsValid(id) then
				return orig(...)
			else
				hook.Remove(name, id)
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

hook.Run = function(name, ...)
	hook.Call(name, GAMEMODE, ...)
end

hook.Remove = function(name, id)
	local collection = hooks[name]
	if collection ~= nil then
		local func = mappings[name][id]
		if func ~= nil then
			for k,v in ipairs(collection) do
				if func == v then
					table.remove(collection, k)
					break 
				end
			end
		end
		mappings[name][id] = nil
	end
end


for name, collection in pairs(oldHooks) do
	for id, func in pairs(collection) do
		hook.Add(name, id, func)
	end
end