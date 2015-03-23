if SERVER then
	error 'run this client side'
end

local myself = LocalPlayer()
for i = 1, 1000 do
	hook.Add('BullShitHook', ''..i, function()
		a = 1
		for i=2, 10 do
			a = a * i
		end
	end)
end
for k,v in ipairs(ents.GetAll()) do  
	hook.Add('BullShitHook_Entity', v, function()
		a = 1
		for i = 2, 10 do
			a = a * i
		end
	end)
end


local stoned_hook = {}
do
	local oldhooks 		= hook.GetTable()
	local gamemode		= gmod.GetGamemode()

	local hooks			= {}
	local keys 			= {}

	local hook 			= {}
	local pairs 		= pairs
	local ipairs 		= ipairs
	local isfunction	= isfunction
	local isstring 		= isstring
	local IsValid		= IsValid
	local remove 		= table.remove
	local getinfo 		= debug.getinfo

	local function path(f)
		return getinfo(f).short_src 
	end

	function hook.GetTable()
		local ret = {}
		for a, b in pairs(hooks) do
			ret[a] = ret[a] or {}
			for c, d in ipairs(b) do
				local key = keys[a][c]
				ret[a][key] = d
			end
		end
		return ret
	end

	function hook.Add(event_name, name, func) -- We're even lua refresh friendly
		if isfunction(name) then
			func = name
			name = path(func)
		end
		keys[event_name] 		= keys[event_name]	or {}
		hooks[event_name] 		= hooks[event_name]	or {}
		local key 				= (#hooks[event_name] + 1)
		keys[event_name][name] 	= keys[event_name][name] or key
		key 					= keys[event_name][name]
		keys[event_name][key] 	= keys[event_name][key] or name
		hooks[event_name][key] 	= func
	end

	function hook.Remove(event_name, name)
		if not keys[event_name] or not keys[event_name][name] then return end
		local key = keys[event_name][name]
		keys[event_name][name] 	= nil
		remove(keys[event_name], key)
		remove(hooks[event_name], key)
	end

	function hook.Run(name, ...)
		return hook.Call(name, gamemode, ...)
	end

	function hook.Call(name, gm, ...)
		local hooks_table = hooks[name]
		if (hooks_table ~= nil) then
			local a, b, c, d, e, f
			local key_table = keys[name]
			for k, v in ipairs(hooks_table) do
				local key = key_table[k]
				if isstring(key) then
					a, b, c, d, e, f = v(...)
				else
					if IsValid(key) then
						a, b, c, d, e, f = v(key, ... )
					else
						if key_table[key] then
							key_table[key] = nil
						end
						remove(keys[name], k)
						remove(hooks[name], k)
					end
				end
				if (a ~= nil) then
					return a, b, c, d, e, f
				end
			end
		end
		if (gm == nil) then return end
		local gmfunc = gm[name]
		if (gmfunc == nil) then return end
		return gmfunc(gm, ...) 
	end

	for a, b in pairs(oldhooks) do
		for c, d in pairs(b) do
			hook.Add(a, c, d)
		end
	end
	stoned_hook = hook
end

local last_hook
do
	
	local oldHooks 		= hook.GetTable()

	local hook 				= {}

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
	
	last_hook = hook
end




local SysTime = SysTime
local t = 0
local function start()
	t = SysTime()
end
local function stop()
	return SysTime() - t
end



local stoned_time_ents = 0
local stoned_time = 0
local last_time_ents = 0
local last_time = 0
for i = 1, 10 do
	-- 10 passes

	start()
	local stoned_call = stoned_hook.Call
	for k = 1, 1000 do
		stoned_call('BullShitHook', nil, 1, 2, 3)
	end
	stoned_time = stoned_time + stop()

	start()
	local last_call = last_hook.Call
	for k = 1, 1000 do
		last_call('BullShitHook', nil, 1, 2, 3)
	end
	last_time = last_time + stop()

	start()
	local stoned_call = stoned_hook.Call
	for k = 1, 10000 do
		stoned_call('BullShitHook_Entity', nil, 1, 2, 3)
	end
	stoned_time_ents = stoned_time_ents + stop()

	start()
	local last_call = last_hook.Call
	for k = 1, 10000 do
		last_call('BullShitHook_Entity', nil, 1, 2, 3)
	end
	last_time_ents = last_time_ents + stop()

end

print('stoned time: ' .. stoned_time)
print('last time: ' .. last_time)
print('stoned time ents: ' .. stoned_time_ents)
print('last time ents: ' .. last_time_ents)